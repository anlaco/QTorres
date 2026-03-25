Red [
    Title:   "QTorres — Runner de tests"
    Purpose: "Ejecuta todos los tests y muestra resumen PASS/FAIL"
]

; ── Infraestructura ──────────────────────────────────────────────────
pass-count: 0
fail-count: 0
current-suite: ""

suite: func [name [string!]] [
    current-suite: name
    print rejoin ["^/=== " name " ==="]
]

assert: func [desc [string!] cond [logic!]] [
    either cond [
        pass-count: pass-count + 1
        print rejoin ["  [PASS] " desc]
    ][
        fail-count: fail-count + 1
        print rejoin ["  [FAIL] " desc]
    ]
]

assert-error: func [desc [string!] body [block!] /local err] [
    err: try body
    assert desc (error? err)
]

; ── Suites ───────────────────────────────────────────────────────────
do %test-blocks.red
do %test-model.red
do %test-topo-sort.red
do %test-compiler.red

; ── Resumen ──────────────────────────────────────────────────────────
total: pass-count + fail-count
print rejoin ["^/--- " total " tests, " pass-count " passed, " fail-count " failed"]
either fail-count > 0 [
    print "RESULTADO: FALLO"
    quit/return 1
][
    print "RESULTADO: OK"
    quit/return 0
]
