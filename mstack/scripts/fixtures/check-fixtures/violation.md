# violation fixture — bad id, empty cell, bad verdict, duplicate

| ID | Prompt | Expected route | Expected intake verdict |
|----|--------|----------------|--------------------------|
| X1 | bad prefix | skill: `hunt-bugs` | CLEAN |
| P2 |  | skill: `simplify` | PROCEED |
| P3 | make it faster | runbooks/figure-it-out.md | MAYBE |
| P1 | first | skill: `hunt-bugs` | CLEAN |
| P1 | duplicate | skill: `simplify` | PROCEED |
