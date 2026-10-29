# Chemistry 9701 — syllabus point is NOT the textbook chapter number

Source audit (book provided to the project): *Cambridge International AS & A Level Chemistry Coursebook, 3rd edition*, Lawrie Ryan and Roger Norris. Its contents give chapter 13 **Nitrogen**, chapter 14 **Introduction to organic chemistry**, chapter 15 **Hydrocarbons**, chapter 16 **Halogenoalkanes**, chapter 17 **Alcohols, esters and carboxylic acids**, chapter 18 **Carbonyl compounds**, chapter 28 **Polymerisation**, chapter 29 **Organic synthesis** and chapter 30 **Analytical chemistry**.

The official Cambridge 9701 **2025–2027 syllabus** instead numbers **13** AS Introduction to organic chemistry, **20.1** AS Addition polymerisation and **22** AS Analytical techniques. The syllabus and book use **different numbering systems**. Never turn `syllabus_point=20.1` into `book_ref=ch20`, or `syllabus_point=13.4` into textbook chapter 13 automatically: both will be wrong.

The protected J23 Theory candidate stores `syllabus_point` but does not have a `book_ref` column. Before displaying any reading recommendation, require an explicit independently verified mapping from each skill to the book chapter and printed page, marking topics not covered at AS level in this edition as `no direct AS chapter` rather than making up pages. This is a source-data governance requirement, **not an assertion that existing rows have wrong `book_ref` values**.

Official syllabus: https://www.cambridgeinternational.org/Images/664563-2025-2027-syllabus.pdf . Source book: user-uploaded Cambridge Coursebook 3e, contents pages. Metadata-only public note, no protected answer text. J24 OFF/J25 CLOSED.
