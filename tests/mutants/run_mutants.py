#!/usr/bin/env python3
"""Mutation testing for the four formalisations.

A proof assistant exiting 0 says "this file type-checks".  It does not say the
file is *about* the right thing.  Mutation testing probes that: perturb the
source in a way that should make the development FALSE, rebuild, and see
whether the build notices.

    KILLED   the build fails  -> the proof really depends on what was changed
    SURVIVED the build passes -> nothing in the development pins that down

A SURVIVED mutant is not automatically a bug; some are expected (the
catalogue's `expect` column says which), and those are the interesting rows:
they map out exactly which parts of the text the machine is NOT checking.

Usage
    ./run_mutants.py                      # every system (slow: hours)
    ./run_mutants.py --system coq         # one system
    ./run_mutants.py --only C04,C10       # named mutants
    ./run_mutants.py --list               # dry run: check the catalogue applies
"""

import argparse
import csv
import os
import shutil
import subprocess
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))          # repository root
CATALOGUE = os.path.join(HERE, "catalogue.tsv")
RESULTS = os.path.join(HERE, "results.tsv")
HOME = os.path.expanduser("~")

COQ_FILES = ["SLA_Prelim.v", "SLA_Chapter4.v", "SLA_AppendixA.v", "SLA_Instance.v"]
COQC = os.environ.get("COQC", "/usr/bin/coqc")

TIMEOUT = {"coq": 600, "lean": 2400, "isabelle": 1800, "keymaerax": 900}


def run(cmd, cwd, timeout, env=None):
    """Return (exit code, tail of combined output).  124 on timeout."""
    e = dict(os.environ)
    if env:
        e.update(env)
    try:
        p = subprocess.run(cmd, cwd=cwd, timeout=timeout, env=e,
                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        return p.returncode, p.stdout.decode("utf-8", "replace")[-4000:]
    except subprocess.TimeoutExpired:
        return 124, "TIMEOUT after %ds" % timeout


def apply_mutation(path, find, replace):
    """Exact, single-occurrence textual replacement.  Raises if ambiguous."""
    with open(path, encoding="utf-8") as fh:
        src = fh.read()
    n = src.count(find)
    if n != 1:
        raise ValueError("pattern occurs %d times (want exactly 1) in %s: %r"
                         % (n, path, find[:60]))
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(src.replace(find, replace))


# --------------------------------------------------------------------------
# per-system builders: each returns (verdict_build, verdict_tests, note)
# verdicts are "ok" (built) or "fail" (did not build)
# --------------------------------------------------------------------------

def build_coq(mut, work):
    """Copy coq/ and tests/coq/, mutate, build the library, then the tests."""
    shutil.copytree(os.path.join(ROOT, "coq"), os.path.join(work, "coq"))
    shutil.copytree(os.path.join(ROOT, "tests", "coq"), os.path.join(work, "tests"))
    for junk in os.listdir(os.path.join(work, "coq")):
        if junk.endswith((".vo", ".vok", ".vos", ".glob")):
            os.remove(os.path.join(work, "coq", junk))

    apply_mutation(os.path.join(work, mut["file"]), mut["find"], mut["replace"])

    coqdir = os.path.join(work, "coq")
    note = ""
    for f in COQ_FILES:
        rc, out = run([COQC, "-Q", ".", "SLA", f], coqdir, TIMEOUT["coq"])
        if rc != 0:
            return "fail", "skip", "lib: %s: %s" % (f, first_error(out))
    # library built; now the tests
    tests = sorted(f for f in os.listdir(os.path.join(work, "tests")) if f.endswith(".v"))
    for f in tests:
        rc, out = run([COQC, "-Q", os.path.join(work, "coq"), "SLA", f],
                      os.path.join(work, "tests"), TIMEOUT["coq"])
        if rc != 0:
            return "ok", "fail", "tests: %s: %s" % (f, first_error(out))
    return "ok", "ok", note


def build_isabelle(mut, work):
    shutil.copytree(os.path.join(ROOT, "isabelle"), os.path.join(work, "isabelle"))
    apply_mutation(os.path.join(work, mut["file"]), mut["find"], mut["replace"])
    isabelle = os.environ.get("ISABELLE", os.path.join(HOME, "Isabelle2025-2", "bin", "isabelle"))
    rc, out = run(["nice", "-n", "15", isabelle, "build", "-d", ".", "-o", "threads=2",
                   "-o", "document=false", "SLA"],
                  os.path.join(work, "isabelle"), TIMEOUT["isabelle"])
    return ("ok" if rc == 0 else "fail"), "-", first_error(out)


def build_lean(mut, work):
    """Lean is mutated IN PLACE: the 7 GB Mathlib cache cannot be copied.
    The source is restored from a backup afterwards, whatever happens."""
    path = os.path.join(ROOT, mut["file"])
    backup = path + ".mutantbak"
    shutil.copy2(path, backup)
    try:
        apply_mutation(path, mut["find"], mut["replace"])
        env = {"PATH": os.path.join(HOME, ".elan", "bin") + ":" + os.environ["PATH"]}
        rc, out = run(["nice", "-n", "15", "lake", "build"],
                      os.path.join(ROOT, "lean"), TIMEOUT["lean"], env)
        return ("ok" if rc == 0 else "fail"), "-", first_error(out)
    finally:
        shutil.move(backup, path)


def build_keymaerax(mut, work):
    shutil.copytree(os.path.join(ROOT, "keymaerax"), os.path.join(work, "keymaerax"))
    apply_mutation(os.path.join(work, mut["file"]), mut["find"], mut["replace"])
    tools = os.environ.get("KYX_TOOLS", os.path.join(HOME, "kyx-tools"))
    java_home = os.path.join(tools, "jdk-21.0.12+8")
    entry = os.path.basename(mut["file"])
    rc, out = run(["nice", "-n", "15", os.path.join(java_home, "bin", "java"),
                   "-Xmx2g", "-Xss20M", "-jar", os.path.join(tools, "keymaerax.jar"),
                   "-launch", "-prove", entry,
                   "-tool", "z3", "-z3path", os.path.join(tools, "z3wrap", "z3"),
                   "-timeout", "200"],
                  os.path.join(work, "keymaerax"), TIMEOUT["keymaerax"],
                  {"JAVA_HOME": java_home})
    return ("ok" if rc == 0 else "fail"), "-", first_error(out)


BUILDERS = {"coq": build_coq, "isabelle": build_isabelle,
            "lean": build_lean, "keymaerax": build_keymaerax}


def first_error(out):
    for line in out.splitlines():
        s = line.strip()
        if any(k in s for k in ("Error", "error:", "*** ", "Failed", "UNFINISHED",
                                "TIMEOUT", "unsolved", "Unfinished")):
            return s[:160]
    return out.strip().splitlines()[-1][:160] if out.strip() else ""


def verdict(build, tests, mut):
    """KILLED if the mutant was rejected somewhere it was expected to be."""
    got_build = "SURVIVED" if build == "ok" else "KILLED"
    got_tests = {"ok": "SURVIVED", "fail": "KILLED", "skip": "n/a", "-": "-"}[tests]
    norm = {"kill": "KILLED", "survive": "SURVIVED", "skip": "n/a", "-": "-"}
    want_build = norm.get(mut["expect_build"].strip().lower(), mut["expect_build"].upper())
    want_tests = norm.get(mut["expect_tests"].strip().lower(), mut["expect_tests"].upper())
    ok = (got_build == want_build)
    if want_tests not in ("-",):
        ok = ok and (got_tests == want_tests)
    return got_build, got_tests, ok


def restore_stale_backups():
    """If a previous run was killed mid-Lean-mutant, the source is still
    mutated and a .mutantbak sits next to it.  Put it back before doing
    anything else."""
    for root, _dirs, files in os.walk(os.path.join(ROOT, "lean")):
        for f in files:
            if f.endswith(".mutantbak"):
                bak = os.path.join(root, f)
                shutil.move(bak, bak[: -len(".mutantbak")])
                print("restored stale backup: %s" % bak, flush=True)


def main():
    restore_stale_backups()
    ap = argparse.ArgumentParser()
    ap.add_argument("--system", action="append", default=None)
    ap.add_argument("--only", default=None, help="comma-separated mutant ids")
    ap.add_argument("--list", action="store_true", help="only check the patterns apply")
    args = ap.parse_args()

    with open(CATALOGUE, encoding="utf-8") as fh:
        rows = [r for r in csv.DictReader(fh, delimiter="\t") if r["id"] and not r["id"].startswith("#")]
    for r in rows:                      # \n in the catalogue means a real newline
        r["find"] = r["find"].replace("\\n", "\n")
        r["replace"] = r["replace"].replace("\\n", "\n")
    if args.system:
        rows = [r for r in rows if r["system"] in args.system]
    if args.only:
        want = set(args.only.split(","))
        rows = [r for r in rows if r["id"] in want]

    if args.list:
        bad = 0
        for r in rows:
            src = open(os.path.join(ROOT, r["file"]), encoding="utf-8").read()
            n = src.count(r["find"])
            flag = "ok " if n == 1 else "BAD"
            if n != 1:
                bad += 1
            print("%s %-5s %-4s %s  (%d hits)" % (flag, r["id"], r["system"], r["file"], n))
        print("\n%d/%d patterns are unique" % (len(rows) - bad, len(rows)))
        return 1 if bad else 0

    results = []
    for r in rows:
        t0 = time.time()
        work = tempfile.mkdtemp(prefix="mut_%s_" % r["id"],
                                dir=os.environ.get("MUT_TMP", tempfile.gettempdir()))
        try:
            build, tests, note = BUILDERS[r["system"]](r, work)
        except Exception as exc:                      # malformed mutant
            build, tests, note = "error", "-", str(exc)[:160]
        finally:
            shutil.rmtree(work, ignore_errors=True)
        dt = time.time() - t0
        gb, gt, ok = verdict(build, tests, r)
        results.append(dict(id=r["id"], system=r["system"], file=r["file"],
                            build=gb, tests=gt, expected="%s/%s" % (r["expect_build"], r["expect_tests"]),
                            as_expected="yes" if ok else "NO", secs="%.0f" % dt,
                            rationale=r["rationale"], note=note))
        print("%-5s %-10s build=%-8s tests=%-8s expected=%-18s %s  [%.0fs]  %s"
              % (r["id"], r["system"], gb, gt, "%s/%s" % (r["expect_build"], r["expect_tests"]),
                 "as expected" if ok else "*** DEVIATION ***", dt, note[:70]), flush=True)

    if results:
        newfile = not os.path.exists(RESULTS)
        with open(RESULTS, "a", encoding="utf-8", newline="") as fh:
            w = csv.DictWriter(fh, delimiter="\t", fieldnames=list(results[0].keys()))
            if newfile:
                w.writeheader()
            w.writerows(results)
        print("\nwrote %d rows to %s" % (len(results), RESULTS))
    dev = [r for r in results if r["as_expected"] == "NO"]
    print("%d/%d mutants behaved as catalogued" % (len(results) - len(dev), len(results)))
    return 1 if dev else 0


if __name__ == "__main__":
    sys.exit(main())
