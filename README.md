# academic

Academic work of **Pedro Yochinori Gushiken**: Electrical Engineering at UFRN (until 2015) and an MSc at PPgEEC/UFRN (2016–2018, advisor Prof. Aldayr Dantas de Araújo) on **second-level adaptation**. The repository also holds a machine-checked formalisation of the dissertation's core chapter.

| Folder | What's in it |
|---|---|
| [`sla-machine-checked/`](sla-machine-checked/) | Formalisation of Chapter 4 and Appendix A of the dissertation in **Coq, Lean 4/Mathlib, Isabelle/HOL and KeYmaera X**. It found two results that don't hold as stated, (4.58) and (4.69), and that the design rule must be `N = 2n+1`. See its [README](sla-machine-checked/README.md). |
| [`dissertation/`](dissertation/) | The MSc dissertation (2018): final PDF, committee version, defense and qualification slides, chapter drafts, research notes, and the MATLAB code behind its figures. |
| [`papers/`](papers/) | CBA 2016 (published), plus the forgetting-factor follow-up (submitted to CBA 2018 and SBAI 2019). Each paper has its PDF, LaTeX, slides and simulation code. |
| [`classwork/`](classwork/) | Undergraduate and graduate course reports, slides and simulations (MATLAB/Simulink/PSIM), organised as `<level>/<year>-<semester>-<course>/`. Includes the undergraduate thesis (TCC, 2015). |
| [`study_material/`](study_material/) | Catalog of the books, papers, theses and course handouts by other authors that this work used. The files are in a separate private repository because they are copyrighted. |
| [`CLASSMATE_WORK.md`](CLASSMATE_WORK.md) | Credits for files written by classmates and other authors that were in the same archive but are **not** included here, and a list of items held back for privacy. |
| [`catalog.csv`](catalog.csv) | One row per file: title, authors, what it is, which course/paper/chapter it belongs to, role (final / draft / experiment…), and where it originally lived. |

## Timeline

- **2015, undergraduate:** drives, communications, substations, installations, internship. Took the graduate *Controle Adaptativo* course, whose PE-attenuation "bonus" idea became the **TCC** on automatic switch-off of the persistently exciting signal (Dec 2015).
- **2016:** MSc starts with Narendra's second-level adaptation. Wrote a MATLAB toolbox. Published the **CBA 2016** paper (second-level adaptation with fixed models and PE switch-off). Courses: Control Systems, Adaptive Control, Information Theoretic Learning, Numerical Linear Algebra.
- **2017–2018:** qualification (Jun 2017), **dissertation** defended 31 Jan 2018. Forgetting-factor paper submitted to CBA 2018, then SBAI 2019.
- **2026:** machine-checked formalisation of Chapter 4 and Appendix A (`sla-machine-checked/`).

## Co-authors and classmates

Joint work is included with all authors credited in the folder READMEs. The co-authors are:
- Prof. Aldayr Dantas de Araújo
- Isaac Dantas Isidório
- Luan Garcia
- José Verismar Júnior
- Felipe Ferreira Moreira
- Frankelene Pinheiro de Souza
- Lucas Marcelino dos Santos
- Prof. Kurios Queiroz
- Isael Calistrato Jácome

Work written **solely** by other students is not published here; it is credited in [`CLASSMATE_WORK.md`](CLASSMATE_WORK.md). Personal data (addresses, phone numbers, ID numbers, other people's e-mail addresses) has been removed from the published LaTeX sources. Compiled PDFs that print such data are not included.

## Notes

- **Simulations** keep their original file names and folder layout so that PSIM subcircuits and MATLAB `load(...)` paths keep working; `catalog.csv` explains each one. PSIM files need PSIM 9; `.slx` files need MATLAB/Simulink (R2015a or later). Large generated outputs (PSIM `.smv` waveforms, workspaces >10 MB) are not included.
- **LaTeX** sources are included where they survive. Most compile with TeX Live: the papers use the SBA `sbatex` class and the theses/slides use abnTeX2. The final dissertation's LaTeX source was not found.

## Licence

- [`sla-machine-checked/`](sla-machine-checked/) is MIT-licensed ([licence](sla-machine-checked/LICENSE)).
- Everything else (papers, dissertation, coursework, code) is © its authors, all rights reserved, and is published here for reference. Co-authored items remain the joint work of the authors listed.
- Third-party LaTeX classes and styles (abnTeX2, `sbatex`, `harvard.sty`, IEEEtran) keep their own licences.
