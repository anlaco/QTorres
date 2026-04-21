Red [Title: "Telekino — Tests .qlib"]

do %../src/graph/model.red

; ── Tests de librería .qlib ──────────────────────────────────────────────

suite "qlib — load-qlib"

; Fichero no existente
assert "load-qlib none si fichero no existe" (
    none? load-qlib %/tmp/no-existe.qlib
)

; Directorio en vez de fichero
assert "load-qlib none si se pasa directorio" (
    none? load-qlib to-file rejoin [form what-dir "../src/"]
)

; Cargar math.qlib del ejemplo (fichero único)
_qlib-file: to-file rejoin [form what-dir "../examples/math.qlib"]
_q: load-qlib _qlib-file

assert "load-qlib devuelve objeto para math.qlib" (object? _q)
assert "load-qlib name correcto"    (_q/name = "math")
assert "load-qlib version correcta" (_q/version = 1)
assert "load-qlib members no vacío" (not empty? _q/members)
assert "load-qlib members son file!" (file? first _q/members)

_found-add: false
foreach _m _q/members [if find form _m "add.qvi" [_found-add: true]]
assert "load-qlib add.qvi está en members" _found-add

_found-sub: false
foreach _m _q/members [if find form _m "subtract.qvi" [_found-sub: true]]
assert "load-qlib subtract.qvi está en members" _found-sub

_all-exist: true
foreach _m _q/members [unless exists? _m [_all-exist: false]]
assert "load-qlib todos los miembros existen en disco" _all-exist

suite "qlib — find-qlibs"

_examples-dir: to-file rejoin [form what-dir "../examples/"]
_libs: find-qlibs/from _examples-dir

assert "find-qlibs devuelve bloque"            (block? _libs)
assert "find-qlibs encuentra math.qlib"        (not empty? _libs)
_first-lib: first _libs
assert "find-qlibs primer resultado es objeto" (object? _first-lib)
assert "find-qlibs primer resultado tiene name" (string? _first-lib/name)

_libs-empty: find-qlibs/from to-file rejoin [form what-dir "../src/"]
assert "find-qlibs devuelve bloque vacío si no hay .qlib" (block? _libs-empty)
assert "find-qlibs vacío si no hay .qlib" (empty? _libs-empty)

suite "qlib — ejemplo usa-libreria"

_ejemplo-path: to-file rejoin [form what-dir "../examples/usa-libreria.qvi"]
assert "usa-libreria.qvi existe" (exists? _ejemplo-path)

_add-path: to-file rejoin [form what-dir "../examples/math/add.qvi"]
assert "math/add.qvi existe" (exists? _add-path)

_sub-path: to-file rejoin [form what-dir "../examples/math/subtract.qvi"]
assert "math/subtract.qvi existe" (exists? _sub-path)

_qlib-path: to-file rejoin [form what-dir "../examples/math.qlib"]
assert "math.qlib es fichero (no directorio)" (
    all [exists? _qlib-path  not dir? _qlib-path]
)
