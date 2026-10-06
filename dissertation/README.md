# MSc dissertation (2018)

**Pedro Yochinori Gushiken**, *Adaptação de Segundo Nível como Técnica de Estimação de Parâmetros e sua Aplicação ao Controle Adaptativo por Modelo de Referência*, MSc dissertation, PPgEEC/UFRN, 2018. Advisor: Prof. Aldayr Dantas de Araújo. Defended 31 Jan 2018.

| Folder | Contents |
|---|---|
| `final/` | Final PDF (with and without the catalog card) and `gushiken-2018-dissertacao-formalization-reference.pdf`, the copy whose page numbers the proofs in [`../sla-machine-checked/`](../sla-machine-checked/) cite. |
| `defense/` | Committee version (13 Jan 2018) and defense slides. |
| `qualification/` | Qualification text and slides (Jun 2017). |
| `drafts/` | Chapter drafts (CH1–CH3), full drafts, post-defense corrections, abstract, and an early LaTeX draft (Sep 2016) built on the TCC template. |
| `notes/` | Research notes: IDMARC notes, a parallel-learning stability proof, paper-idea drafts, the 2016 research-seminar slides, defense-correction list and naming notes. |
| `code/` | MATLAB code behind the figures: `Algoritmos Capítulo 2…5/` (add `code/` to the MATLAB path for the `SISOPLOT_*` / `PLOT_VS_O2` helpers), the 2016 second-level-adaptation toolbox and its history (`2016-second-level-adaptation-toolbox/`), 2016 experiments, and the early Narendra Simulink models (Apr 2016). |

**The LaTeX source of the final dissertation was not found** anywhere in the archive; only the PDFs and an early 2016 draft source survive.

Script → figure map (from the code): Ch. 2 `L1_Filtragem_O1`, `L2_3M/4M/8M_Filtragem_O1` → Figs 2.2–2.5, `L2mod_3M_Filtragem_O1_Figs` → 2.6–2.9; Ch. 3 `L1A_EST`, `L1A_Filtragem`, `L1A_VS`, `L2A_3M_Filtragem_O1` → 3.2–3.7; Ch. 4 `L1_SISOF_O2`, `L2_5M_SISOF_O2(_FE)` → 4.1–4.6; Ch. 5 `L1A_SISOF_O2`, `L2A_5M_SISOF_O2`, `L1A_EST_SISOF_O2`, `L1A_VS_SISOF_O2` → 5.1–5.18. Some parameters in the code differ from the printed text (e.g. λ in `L1_Filtragem_O1`; Λ and Γ in Ch. 5), so not every figure reproduces exactly. Missing helpers: `gif.m` (File Exchange), `L1_Paralelo_O1`, `L1_Serie_Paralelo_O1`, `L2_3M_Serie_Paralelo_O1`.

## Documents

### `defense/`

- `defense-presentation-slides-2018-01-31.pdf` — MSc defense presentation slides (Jan 31 2018)
- `dissertation-committee-version-2018-01-13.pdf` — MSc dissertation, version sent to the examining committee (banca), Jan 13 2018

### `drafts/`

- `abstract-draft-v1.docx` — Dissertation abstract (Resumo) draft v1, Word version, Dec 2017
- `abstract-draft-v1.pdf` — Dissertation abstract (Resumo) draft v1, Dec 2017
- `chapter-1-draft-v1.pdf` — Dissertation chapter 1 draft v1
- `chapter-1-draft-v1r.pdf` — Dissertation chapter 1 draft v1r
- `chapter-1-draft-v1r2.pdf` — Dissertation chapter 1 draft v1r2
- `chapter-1-draft-v1r3.pdf` — Dissertation chapter 1 draft v1r3
- `chapter-1-draft-v2.pdf` — Dissertation chapter 1 draft v2
- `chapter-1-draft-v2r1.pdf` — Dissertation chapter 1 draft v2r1
- `chapter-1-draft-v3.pdf` — Dissertation chapter 1 draft v3
- `chapter-1-draft-v3r1.pdf` — Dissertation chapter 1 draft v3r1
- `chapter-2-draft-v1.pdf` — Dissertation chapter 2 draft v1
- `chapter-2-draft-v1r1.pdf` — Dissertation chapter 2 draft v1r1
- `chapter-2-draft-v1r2.pdf` — Dissertation chapter 2 draft v1r2
- `chapter-2-draft-v1r3.pdf` — Dissertation chapter 2 draft v1r3
- `chapter-3-draft-v1.pdf` — Dissertation chapter 3 draft v1
- `chapter-3-draft-v2.pdf` — Dissertation chapter 3 draft v2
- `dissertation-full-draft-v1-2017-12-20.pdf` — MSc dissertation, first full draft (v1), Dec 20 2017
- `dissertation-full-draft-v96-2018-01-02.pdf` — MSc dissertation, full draft "v96", Jan 2 2018
- `dissertation-post-defense-corrections-2018-03-18.pdf` — MSc dissertation, post-defense corrected version (before final)

### `drafts/2016-early-draft-latex/`

- `TCC - Main.pdf`
- `TCC - Main.tex` — LaTeX source
- …plus 2 LaTeX support files (figures, bibliography, class/style files)

### `drafts/2016-early-draft-latex/pics/`

- …plus 47 LaTeX support files (figures, bibliography, class/style files)

### `final/`

- `gushiken-2018-dissertacao-final-ficha-catalografica.pdf` — MSc dissertation, final version with library catalog card (ficha catalográfica, 146 f.) *(authors: Pedro Yochinori Gushiken (advisor: Aldayr Dantas de Araújo))*
- `gushiken-2018-dissertacao-final.pdf` — MSc dissertation (final version): "Adaptação de Segundo Nível como Técnica de Estimação de Parâmetros e sua Aplicação ao Controle Adaptativo por Modelo de Referência" *(authors: Pedro Yochinori Gushiken (advisor: Aldayr Dantas de Araújo))*

### `notes/`

- `2016-10-paper-idea-alpha-projection.pdf` — Earlier version of the same idea note ('Projeção dos pesos alfa...'), 10 Oct 2016
- `IFAC_Draft-ideia.pdf`
- `IFAC_Draft-ideia.tex` — LaTeX source
- `Prova de Estabilidade Aprendizado Paralelo.pdf`
- `Prova de Estabilidade Aprendizado Paralelo.tex` — LaTeX source
- `defense-corrections.txt` — Notes: list of corrections requested by the defense committee (Francisco, Josenalde), plus a short personal to-do list
- `idmarc-second-level-adaptation-notes.tex` — Research notes (Portuguese) on IDMARC adaptive-law terms and an idea to combine IDMARC with second level adaptation ('a partir do artigo de Leonardo')
- `matlab-algorithm-naming-notes.txt` — Notes: naming convention of the dissertation MATLAB algorithms (L1/L2, A, O, M, Filtragem/SP/Paralelo, FE, mod)

### `notes/pics/`

- …plus 1 LaTeX support files (figures, bibliography, class/style files)

### `notes/slides/`

- `abntex2-modelo-slides.pdf`
- `abntex2-modelo-slides.tex` — LaTeX source
- `ap_Nar_Rev.pdf`
- `ap_Nar_Rev.tex` — LaTeX source
- …plus 1 LaTeX support files (figures, bibliography, class/style files)

### `notes/slides/pics/Ex_pics/`

- …plus 14 LaTeX support files (figures, bibliography, class/style files)

### `qualification/`

- `qualification-presentation-slides-2017-06-20.pdf` — MSc qualification exam presentation slides (talk dated Jun 22 2017; file saved Jun 20)
- `qualification-presentation-slides-2017-06-21.pdf` — MSc qualification exam presentation slides, "_N" variant saved Jun 21 2017 (probably the version presented)
- `qualification-text-2017-with-corrections.pdf` — MSc qualification text, version with corrections (Jun 8 2017)
- `qualification-text-2017.pdf` — MSc qualification text: "Sobre a Adaptação de Segundo Nível como Técnica de Estimação de Parâmetros em Plantas Lineares Parcialmente Conhecidas e sua Aplicação ao Controle Adaptativo" (Jun 2017)
