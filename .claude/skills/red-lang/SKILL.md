---
name: red-lang
description: Official Red programming language reference — core syntax, View GUI engine, Draw dialect, VID layout dialect, and Parse dialect with idiomatic patterns and common gotchas
---

# Red Programming Language — Complete Reference

Red is a full-stack language inspired by Rebol. It runs on a single binary with no dependencies. Its "code as data" philosophy makes all Red source code manipulable as blocks.

**Official docs:** https://doc.red-lang.org/
**Style guide:** https://github.com/red/docs/blob/master/en/style-guide.adoc

---

## 1. Core Syntax

### Script header
Every Red script must start with a `Red []` header block.

```red
Red [
    Title:   "My script"
    Author:  "Name"
    Version: 0.1.0
]
```

For GUI scripts add `Needs: 'View`:
```red
Red [
    Title: "My GUI app"
    Needs: 'View
]
```

### Comments
```red
; single line comment
;-- visual separator comment (official style)
```

### Datatypes
Red is strongly typed for values, but words (variables) are untyped.

```red
; Scalars
42          ; integer!
3.14        ; float!
true false  ; logic!
#"A"        ; char!
50%         ; percent!

; Text
"hello"         ; string! (single line)
{multi
 line}          ; string! (multi line, preferred for multi-line)
'word           ; lit-word!
word            ; word! (evaluates to its value)
:word           ; get-word! (gets value without evaluation)
word:           ; set-word! (assigns value)

; Collections
[1 2 3]             ; block!
(1 + 2)             ; paren! (evaluates immediately)
#[key: "value"]     ; map!

; Other
%path/to/file       ; file!
http://red-lang.org ; url!
10x20               ; pair! (used for coordinates, sizes)
255.0.0             ; tuple! (used for colors: R.G.B)
```

### Variables — assignment and access
```red
; Assignment (set-word)
x: 42
name: "Red"
pos: 100x200        ; pair! for coordinates

; Access
print x             ; => 42
probe name          ; => "Red" (also prints type info)

; Get without evaluation
:x                  ; returns the value of x without calling it if it's a function
```

### Arithmetic and comparison
```red
10 + 3      ; 13
10 - 3      ; 7
10 * 3      ; 30
10 / 3      ; 3 (integer division)
10 // 3     ; 1 (modulo)
10 ** 2     ; 100 (power)

1 = 1       ; true   (value equality)
1 == 1      ; true   (strict equality — also checks type)
same? a b   ; true if same reference (object identity)
1 <> 2      ; true   (not equal)
1 < 2       ; true
1 > 2       ; false
1 <= 1      ; true
```

### Control flow
```red
; if / unless
if x > 0 [print "positive"]
unless x = 0 [print "nonzero"]

; either (if/else)
either x > 0 [print "positive"] [print "not positive"]

; case (multi-branch)
case [
    x < 0  [print "negative"]
    x = 0  [print "zero"]
    x > 0  [print "positive"]
]

; switch
switch color [
    red   [print "red"]
    blue  [print "blue"]
    green [print "green"]
]

; while
while [x > 0] [
    print x
    x: x - 1
]

; until (runs at least once, stops when true)
until [
    x: x - 1
    x = 0
]

; loop (fixed count)
loop 5 [print "hello"]

; repeat (with index)
repeat i 5 [print i]   ; i goes from 1 to 5

; foreach
foreach item [a b c] [print item]
foreach [key val] [name "Red" version 1] [print [key "=" val]]
```

---

## 2. Functions

### func vs function
- `func` — no automatic `/local` detection; you declare locals in spec with `/local`
- `function` — automatically collects set-words as locals (safer, recommended for most cases)

```red
; func with explicit locals
add-values: func [a b /local result] [
    result: a + b
    result
]

; function with automatic locals
add-values: function [a b] [
    result: a + b   ; result is automatically local
    result
]

; does — no arguments
greet: does [print "Hello"]

; has — only locals, no arguments
init-state: has [counter] [
    counter: 0
    counter
]
```

### Refinements
Refinements add optional behavior to functions.

```red
greet: func [name /formal /local greeting] [
    greeting: either formal ["Good day"] ["Hello"]
    print [greeting name]
]

greet "Alice"           ; Hello Alice
greet/formal "Alice"   ; Good day Alice
```

### Return values
The last evaluated expression is the return value. Use `return` for early exit.

```red
sign: func [n] [
    if n < 0 [return 'negative]
    if n = 0 [return 'zero]
    'positive
]
```

---

## 3. Objects and Contexts

Red uses prototype-based objects via `make object!` or `context []`.

```red
; Creating an object
point: make object! [
    x: 0
    y: 0
]

; Accessing fields
point/x: 10
print point/y       ; 0

; context [] is equivalent shorthand
point: context [x: 0  y: 0]

; Inheritance — inheriting from a prototype
point-3d: make point [z: 0]
point-3d/x: 5
point-3d/z: 3
```

### object? and same?
```red
object? point       ; true
same? point point   ; true (identity)
```

### Accessing fields dynamically
```red
field: 'x
point/:field        ; => 10 (get-path with variable)
point/:field: 99    ; set-path with variable
```

---

## 4. Series Operations

Strings, blocks, and paths are all series — they share a common set of operations.

> ⚠️ **CRITICAL GOTCHA:** Series are passed by reference. Always `copy` when you need independence.

```red
a: [1 2 3]
b: a            ; b and a point to the same block!
b: copy a       ; b is now independent

; Shallow vs deep copy
b: copy a           ; shallow — nested blocks still shared
b: copy/deep a      ; deep — fully independent
```

### Common series operations
```red
blk: [10 20 30]

append blk 40               ; [10 20 30 40]
insert blk 0                ; [0 10 20 30 40]
remove blk                  ; removes head: [10 20 30 40]
remove/part blk 2           ; removes 2 elements from head
length? blk                 ; 3
first blk                   ; 10
last blk                    ; 30
pick blk 2                  ; 20 (1-based index)
blk/2                       ; 20 (path access, 1-based)
find blk 20                 ; returns series from 20 onward, or none
select blk 20               ; returns element after 20
index? find blk 20          ; position of 20 (1-based)
head blk                    ; returns head of series
next blk                    ; advances position by 1
skip blk 2                  ; advances position by n
reverse blk                 ; reverses in place
sort blk                    ; sorts in place

; remove-each (filter)
remove-each n blk [n < 20]  ; removes elements where condition is true

; foreach with index — use forall
forall blk [print [index? blk "=>" blk/1]]
```

### String operations
```red
s: "Hello World"
length? s               ; 11
uppercase s             ; "HELLO WORLD"
lowercase s             ; "hello world"
trim s                  ; removes leading/trailing whitespace
find s "World"          ; returns "World" tail
replace s "World" "Red" ; "Hello Red"
split s " "             ; ["Hello" "World"]
form 42                 ; "42" — converts any value to string
mold [1 2 3]            ; "[1 2 3]" — source representation
rejoin ["a" 1 "b"]      ; "a1b" — concatenate mixed types
```

---

## 5. Blocks and compose

`compose` is the standard way to build blocks with dynamic values.

```red
x: 10
color: 255.0.0

; compose — evaluates (parentheses)
compose [line-width (x) pen (color)]
; => [line-width 10 pen 255.0.0]

; compose/deep — evaluates nested parens
compose/deep [box [(as-pair x x)] [(as-pair 100 100)]]

; reduce — evaluates all words
reduce [1 + 1  2 + 2]
; => [2 4]
```

### append vs insert
```red
blk: copy [1 2]
append blk 3            ; [1 2 3]
append blk [4 5]        ; [1 2 3 4 5]  (flattens one level)
append/only blk [4 5]   ; [1 2 3 [4 5]] (appends as single element)
insert blk 0            ; [0 1 2 3 [4 5]]
```

---

## 6. Parse Dialect

`parse` processes series (strings, blocks) using grammar rules.

```red
; Returns true/false (matched entire input)
parse [1 2 3] [some integer!]   ; true
parse "hello" [some alpha]       ; true

; Basic rules
parse input [
    rule1               ; match rule1
    rule1 rule2         ; sequence: match rule1 then rule2
    rule1 | rule2       ; alternative: rule1 or rule2
    opt rule1           ; optional (0 or 1)
    any rule1           ; zero or more (Kleene star)
    some rule1          ; one or more (Kleene plus)
    3 rule1             ; exactly 3 times
    1 3 rule1           ; 1 to 3 times
    skip                ; any single element
    end                 ; end of input
]

; Extracting values
result: none
parse [42] [set result integer!]    ; result = 42
result: copy []
parse [1 2 3] [collect [keep (integer!) some integer!]]

; Named rules
digit: charset "0123456789"
alpha: charset [#"a" - #"z" #"A" - #"Z"]

parse "abc123" [some alpha  some digit]   ; true

; Working on blocks
parse [add 1 2] ['add set a integer! set b integer!]  ; a=1 b=2

; into — parse nested block
parse [[1 2] [3 4]] [into [integer! integer!]]
```

---

## 7. View Dialect — GUI Engine

View manages a tree of `face!` objects that map to native OS widgets.

### Creating a window with view/layout
```red
; Simple approach via VID (Visual Interface Dialect)
view [
    text "Name:"
    name-field: field 200
    button "OK" [print name-field/text]
]

; view with options
view/flags [
    text "Hello"
] 'resize    ; resizable window
```

### Face object — low-level
```red
; Create a face directly
my-face: make face! [
    type:   'base           ; face type (see types below)
    offset: 10x10          ; pair! — position relative to parent
    size:   200x100        ; pair! — width x height
    color:  200.200.200    ; tuple! — R.G.B
    text:   "Hello"        ; string! — displayed text
    extra:  none           ; any! — user data (no UI effect)
    draw:   []             ; block! — Draw dialect commands
    flags:  [all-over]     ; block! — special flags
    pane:   []             ; block! — child faces
    actors: make object! [ ; event handlers
        on-click: func [face event] [...]
    ]
]
```

### Face types
| Type | Description |
|------|-------------|
| `base` | Low-level canvas; use for custom Draw rendering |
| `text` | Static text label |
| `field` | Single-line text input |
| `area` | Multi-line text input |
| `button` | Clickable button |
| `toggle` | On/off button |
| `check` | Checkbox |
| `radio` | Radio button |
| `drop-list` | Read-only dropdown list |
| `drop-down` | Editable dropdown |
| `text-list` | Scrollable item list |
| `progress` | Progress bar (0.0–1.0) |
| `slider` | Slider (0.0–1.0) |
| `calendar` | Date picker |
| `panel` | Container (can use VID layout inside) |
| `group-box` | Labeled container |
| `tab-panel` | Tabbed container |
| `window` | Top-level window |

### Key face facets
```red
face/type           ; word! — face type (read-only after creation)
face/offset         ; pair! — position (x y)
face/size           ; pair! — dimensions (width x height)
face/text           ; string! — displayed text
face/color          ; tuple! — R.G.B background color
face/data           ; any! — face-type-specific data
face/draw           ; block! — Draw commands (redraws on change)
face/image          ; image! — background image
face/extra          ; any! — arbitrary user data (VERY useful for state)
face/flags          ; block! — [all-over popup modal ...]
face/pane           ; block! — child faces (containers)
face/actors         ; object! — event handlers
face/state          ; block! — internal engine state (do not touch)
face/enabled?       ; logic! — enable/disable interaction
face/visible?       ; logic! — show/hide
face/selected       ; integer! — selected item index (list types)
face/rate           ; integer!/time! — timer interval
```

### Actors (event handlers)
All actors receive `face` (the face that triggered) and `event` (event data).

```red
actors: make object! [
    on-click:     func [face event] [...]   ; mouse click
    on-dbl-click: func [face event] [...]   ; double click
    on-down:      func [face event] [...]   ; mouse button down
    on-up:        func [face event] [...]   ; mouse button release
    on-over:      func [face event] [...]   ; mouse movement over face
    on-wheel:     func [face event] [...]   ; mouse wheel scroll
    on-key:       func [face event] [...]   ; key press
    on-key-up:    func [face event] [...]   ; key release
    on-enter:     func [face event] [...]   ; Enter key (field/area)
    on-focus:     func [face event] [...]   ; face gains focus
    on-unfocus:   func [face event] [...]   ; face loses focus
    on-change:    func [face event] [...]   ; value changed
    on-select:    func [face event] [...]   ; item selected (list)
    on-time:      func [face event] [...]   ; timer tick (needs face/rate)
    on-close:     func [face event] [...]   ; window close
    on-resize:    func [face event] [...]   ; window resized
    on-move:      func [face event] [...]   ; window moved
    on-create:    func [face event] [...]   ; face just created
]
```

### Event object fields
```red
event/type      ; word! — event type name
event/offset    ; pair! — mouse position relative to face
event/key       ; char!/word! — key pressed (see below)
event/flags     ; block! — [shift control alt]
event/down?     ; logic! — is mouse button held?
event/ctrl?     ; logic! — is Ctrl held?
event/shift?    ; logic! — is Shift held?
event/window    ; face — the window face
```

### Checking keys in on-key
```red
on-key: func [face event] [
    ; Special keys are word! values
    if event/key = 'delete    [...]
    if event/key = 'backspace [...]
    if event/key = 'escape    [...]
    if event/key = 'return    [...]
    if event/key = 'tab       [...]
    if event/key = 'up        [...]
    if event/key = 'down      [...]
    if event/key = 'left      [...]
    if event/key = 'right     [...]

    ; Printable characters are char! values
    if event/key = #"a"       [...]

    ; Detect delete/backspace including OS variants
    if any [
        find [delete backspace] event/key
        find [#"^(7F)" #"^H"] event/key
    ] [...]
]
```

### view and unview
```red
view layout-block                   ; blocking — waits for window close
view/no-wait layout-block           ; non-blocking — returns immediately (for modals)
view/flags layout-block 'resize     ; with flags
unview                              ; close the most recent view/no-wait window
unview/all                          ; close all windows
```

### Storing state in face/extra
Use `face/extra` to attach model/state to a face. Access it from actors via `face/extra`.

```red
my-canvas: make face! [
    type:  'base
    size:  400x300
    extra: make object! [       ; state lives here
        count:    0
        selected: none
    ]
    actors: make object! [
        on-click: func [face event] [
            face/extra/count: face/extra/count + 1
            face/draw: render face/extra    ; re-render from state
        ]
    ]
]
```

### Forcing a redraw
Assign a new block to `face/draw` — this triggers a redraw:
```red
face/draw: render-function model    ; triggers immediate redraw
```

### Flags
```red
face/flags: [all-over]      ; receive on-over events even when not focused
face/flags: [popup]         ; popup window behavior
face/flags: [modal]         ; blocks input to other windows (GTK: use view/no-wait instead)
```

---

## 8. VID — Visual Interface Dialect

VID is the high-level layout DSL used inside `view []` blocks.

```red
view [
    ; Basic widgets
    text "Label"
    field 200                       ; 200 pixels wide
    area 300x150                    ; width x height
    button "Click me" [action]
    check "Option" [action]
    radio "Choice A" [action]

    ; Layout control
    return                          ; start new row
    across                          ; horizontal layout (default is vertical/below)
    below                           ; vertical layout

    ; Named faces — use name: before type
    my-field: field 200

    ; With initial data
    text-list 200x150 data ["A" "B" "C"]
    drop-list data ["X" "Y" "Z"]

    ; Inline actors
    button "OK" [
        print my-field/text
    ]

    ; Styling
    button "Big" font-size 18 bold
    text "Red" font-color 255.0.0

    ; Positioning
    at 100x50 button "Absolute"     ; absolute position
    pad 10x5                        ; add padding

    ; Panel — nested layout
    panel [
        text "Inside panel"
        button "OK" []
    ]
]
```

---

## 9. Draw Dialect

Draw is a declarative 2D vector graphics dialect. Assign a block of Draw commands to `face/draw`.

### Default state
| Property | Default |
|----------|---------|
| pen | black (0.0.0) |
| fill-pen | off (no fill) |
| line-width | 1 |
| line-join | miter |
| line-cap | flat |
| anti-alias | on |

### Colors
```red
; Colors are tuple! values: R.G.B or R.G.B.A (alpha 0=transparent, 255=opaque)
pen 255.0.0             ; red outline
fill-pen 0.0.255        ; blue fill
pen 255.0.0.128         ; semi-transparent red
pen off                 ; no outline
fill-pen off            ; no fill
```

### Shapes
```red
; line — one or more segments
line 10x10 100x10               ; horizontal line
line 10x10 50x50 100x10         ; polyline (3 points)

; triangle
triangle 10x10 100x10 55x80

; box — rectangle with optional corner radius
box 10x10 200x100               ; sharp corners
box 10x10 200x100 8             ; rounded corners (radius 8)

; polygon — closed shape
polygon 10x10 100x10 150x80 10x80

; circle — center + radius (or pair for ellipse)
circle 100x100 50               ; circle
circle 100x100 50x30            ; ellipse

; ellipse — top-left corner + size
ellipse 10x10 200x100

; arc — center, radius (pair), angles, sweep
arc 100x100 50x50 0 90          ; quarter circle
arc 100x100 50x50 0 180 closed  ; semicircle with closing line

; curve — cubic bezier: start, control1, control2, end
curve 10x10 50x-10 100x50 120x10

; spline — smooth curve through points
spline 10x10 50x80 100x20 150x90
spline/closed 10x10 50x80 100x20 150x90    ; closed spline
```

### Text in Draw
```red
; text — position then string
text 10x10 "Hello"

; font — controla tipografía (familia, tamaño, negrita)
font make font! [name: "Arial" size: 14 bold: true]
text 10x10 "Bold Arial 14"

; Color del texto: se controla con pen, NO con fill-pen ni font/color
pen 255.0.0         ; texto rojo
text 10x10 "Texto rojo"
pen 0.0.0           ; texto negro
text 10x10 "Texto negro"
```

> ⚠️ **GOTCHA — Color de texto en Draw (verificado en GTK/Linux):**
>
> - **`pen`** es lo que colorea el texto. Cambia antes de cada `text`.
> - **`fill-pen`** NO afecta el color del texto (solo relleno de formas).
> - **`font!/color`** es ignorado por GTK/Linux — no tiene efecto sobre el color del texto.
> - **`pen off`** antes de `text` produce texto **gris** (color del sistema), no invisible.
> - **`pen` sangra entre comandos `text`**: si no reseteas, el siguiente `text` hereda el color anterior.
> - **`line-width`** no afecta al texto.
>
> Patrón correcto para resetear estado Draw entre items (panel.red):
> ```red
> pen 0.0.0  fill-pen off  line-width 1
> ; — pen 0.0.0   → texto negro (reset crítico)
> ; — fill-pen off → formas sin relleno (reset de formas)
> ; — line-width 1 → grosor por defecto
> ; — font!/color  → NO usar para color, no funciona en GTK
> ```

### Styling
```red
line-width 2                ; line thickness in pixels
line-width 0.5              ; sub-pixel (float)

line-join miter             ; sharp corners (default)
line-join round             ; rounded corners
line-join bevel             ; cut corners

line-cap flat               ; flat ends (default)
line-cap square             ; square ends (extends beyond endpoint)
line-cap round              ; rounded ends

anti-alias on               ; smooth edges (default)
anti-alias off              ; pixel-perfect (no smoothing)
```

### Gradients
```red
; linear gradient: start-point end-point [color1 color2 ...]
pen linear 0x0 200x0 [255.0.0 0.0.255]             ; red to blue, left to right
fill-pen linear 0x0 0x200 [255.255.255 0.0.0]       ; white to black, top to bottom

; radial gradient: center outer-center focal-radius spread [colors]
fill-pen radial 100x100 100x100 0 80 [255.255.255 0.0.0]

; diamond gradient
fill-pen diamond 100x100 100x100 0 80 [255.255.0 0.0.255]
```

### Transformations
```red
; push — save/restore state (like gsave/grestore in PostScript)
push [
    rotate 45
    box 50x50 150x150       ; drawn rotated
]
; state restored after push block

rotate 45                   ; rotate by 45 degrees around origin
rotate 45 100x100           ; rotate around point 100x100
scale 2.0 1.5               ; scale x by 2, y by 1.5
translate 50x30             ; move origin
skew 20 0                   ; skew x-axis by 20 degrees
reset-matrix                ; reset to identity transform
```

### Clipping
```red
clip 10x10 200x200          ; clip to rectangle
clip [circle 100x100 80]    ; clip to arbitrary shape
```

### Complete example — custom canvas
```red
Red [Title: "Draw example" Needs: 'View]

draw-scene: func [w h] [
    compose [
        ; Background
        fill-pen 220.230.240
        box 0x0 (as-pair w h)

        ; Grid dots
        pen 180.190.200  fill-pen 180.190.200
        ; (loop to generate grid points)

        ; A rounded block
        pen 30.60.120  line-width 1  fill-pen 50.100.180
        box 50x50 170x100 6

        ; Text on the block
        fill-pen 240.245.250
        text 60x65 "CTRL"

        ; A port circle
        pen 50.110.200  fill-pen 50.110.200
        circle 42x68 8

        ; Selection highlight
        pen 0.175.210  line-width 2  fill-pen off
        box 44x44 176x106 8
        line-width 1
    ]
]

view [
    canvas: base 400x300 draw (draw-scene 400 300)
]
```

---

## 10. Idiomatic Patterns

### Pattern: Model + pure render function
Separate state from rendering. The render function takes the model and returns a Draw block.

```red
; Model
make-model: func [] [
    make object! [
        nodes: copy []
        selected: none
    ]
]

; Pure render — no side effects, returns Draw block
render: func [model /local cmds] [
    cmds: copy []
    foreach node model/nodes [
        append cmds compose [
            fill-pen (node/color)
            box (as-pair node/x node/y) (as-pair (node/x + 100) (node/y + 50)) 4
        ]
    ]
    cmds
]

; In the canvas actor:
on-click: func [face event] [
    ; mutate model
    face/extra/selected: hit-test face/extra event/offset/x event/offset/y
    ; re-render
    face/draw: render face/extra
]
```

### Pattern: as-pair for coordinates
```red
; as-pair constructs a pair! from two integers
as-pair 100 50      ; => 100x50
as-pair x y         ; => (value of x)x(value of y)

; pair arithmetic
pos: 100x50
pos + 10x5          ; 110x55
pos/x               ; 100
pos/y               ; 50
```

### Pattern: compose for Draw blocks
```red
; Always use compose to inject dynamic values into Draw blocks
x: 50  y: 80  color: 50.100.180

append cmds compose [
    fill-pen (color)
    box (as-pair x y) (as-pair (x + 120) (y + 50)) 5
]
```

### Pattern: object prototype + constructor
```red
; Base prototype
base-node: make object! [
    id:    0
    x:     0
    y:     0
    type:  'default
    label: make object! [text: "" visible: true offset: 0x-15]
]

; Constructor
make-node: func [node-id node-type pos-x pos-y] [
    make base-node [
        id:   node-id
        type: node-type
        x:    pos-x
        y:    pos-y
    ]
]

node: make-node 1 'add 100 80
```

### Pattern: Modal dialog with view/no-wait
On Linux/GTK, `view` with `modal` flag has focus issues. Use `view/no-wait` instead.

```red
; Module-level vars to persist across the async boundary
dialog-result: none
dialog-field:  none

open-dialog: func [initial-text callback-face] [
    dialog-result: none
    dialog-field:  none
    view/no-wait compose [
        title "Enter value"
        text "Value:" return
        dialog-field: field 200 (initial-text)
        on-enter [
            dialog-result: dialog-field/text
            callback-face/draw: re-render callback-face/extra
            unview
        ]
        return
        button "OK" [
            dialog-result: dialog-field/text
            callback-face/draw: re-render callback-face/extra
            unview
        ]
        button "Cancel" [unview]
    ]
]
```

### Pattern: Hit-testing (click detection)
```red
; Check if point (px py) is inside a rectangular area
inside-box?: func [px py box-x box-y box-w box-h] [
    all [
        px >= box-x  px <= (box-x + box-w)
        py >= box-y  py <= (box-y + box-h)
    ]
]

; Check proximity to a point (for ports/handles)
near-point?: func [px py cx cy radius] [
    all [
        (absolute (px - cx)) < radius
        (absolute (py - cy)) < radius
    ]
]
```

### Pattern: remove-each for filtering
```red
; Remove all wires connected to a node
node-id: 5
remove-each wire model/wires [
    any [wire/from-id = node-id  wire/to-id = node-id]
]

; Remove all even numbers
remove-each n numbers [even? n]
```

---

## 11. Naming Conventions (Official Style Guide)

```red
; Variables — lowercase, hyphens, descriptive nouns
block-width: 120
selected-node: none
canvas-face: none

; Functions — start with verb, lowercase, hyphens
make-node: func [...] [...]
render-diagram: func [...] [...]
hit-test: func [...] [...]
canvas-delete-selected: func [...] [...]

; Boolean functions — ? suffix
node?: func [x] [object? x]
inside-box?: func [...] [...]

; Constants — same as variables (Red has no const)
port-radius: 8
grid-size: 20

; Avoid abbreviations — prefer:
;   block-width  over  bw
;   source-node  over  sn
;   draw-cmds    over  d

; /local for explicit locals (func) or use function for automatic
render: func [model /local cmds node wire] [...]
```

### Block formatting rules
```red
; NEVER break before block opening — breaks pasting to REPL
; WRONG:
if x > 0
[print "yes"]

; CORRECT:
if x > 0 [print "yes"]

; Multi-line blocks — indent content, closing ] on own line
if x > 0 [
    do-something
    do-more
]

; Empty block — no spaces
[]

; Function spec on one line
my-func: func [arg1 [integer!] arg2 [string!] /local result] [
    ...
]
```

---

## 12. Common Gotchas

### 1. Series reference aliasing
```red
; WRONG — both vars share the same block
a: [1 2 3]
b: a
append b 4      ; also modifies a!

; CORRECT
b: copy a
```

### 2. compose only evaluates parentheses
```red
x: 10
compose [pen x]         ; => [pen x]   — x NOT evaluated
compose [pen (x)]       ; => [pen 10]  — x IS evaluated
```

### 3. 1-based indexing
```red
blk: [a b c]
blk/1           ; a  (not blk/0)
pick blk 1      ; a
```

### 4. integer division
```red
10 / 3          ; 3   (integer!)
10.0 / 3        ; 3.3333... (float!)
to-float 10 / 3 ; still 3 — division happens first
10.0 / 3.0      ; 3.3333...
```

### 5. set-word vs word in blocks
```red
; Inside a block, set-words DO assign (unlike in Rebol)
blk: [x: 10  y: 20]
do blk          ; assigns x and y in current context
```

### 6. none propagation
```red
; none is falsy; use all/any for short-circuit evaluation
if all [obj  obj/field  obj/field > 0] [...]  ; safe null check chain
```

### 7. as-pair expects integers
```red
x: 10.5
as-pair x 20            ; ERROR — float not accepted
as-pair to-integer x 20 ; CORRECT
```

### 8. Colors are tuples, not blocks
```red
pen [255 0 0]       ; WRONG — block, not a color
pen 255.0.0         ; CORRECT — tuple!
```

### 9. object? vs map?
```red
; make object! creates object! — access with /field
; #[key: value] creates map! — access with/key too, but different semantics
obj: make object! [x: 1]
mp:  #[x: 1]
obj/x               ; 1
mp/x                ; 1 (same syntax, different internals)
object? obj         ; true
map? mp             ; true
```

### 10. View needs: 'View declaration
```red
; Without this, view/draw/make face! are undefined
Red [Needs: 'View]
```

---

## 13. Quick Reference Card

```red
; Types            pair!: 10x20    tuple!: 255.0.0    word!: my-word
; Assign           x: value
; Function         f: func [a b /local c] [c: a + b  c]
; Object           obj: make object! [x: 0  y: 0]
; Field access     obj/x    obj/:word-var
; Block ops        append copy find remove-each foreach
; Compose          compose [pen (color) box (as-pair x y) (as-pair w h)]
; Pair ops         as-pair x y    p/x    p/y    p + 5x5
; Face             make face! [type: 'base  size: 200x100  extra: model]
; Re-render        face/draw: render-function face/extra
; Modal dialog     view/no-wait [...]   unview
; Parse            parse input [some integer!]
; Filter           remove-each item list [condition]
; Type check       integer? x    object? x    none? x    same? a b
```
