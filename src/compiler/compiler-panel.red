Red [
    Title:   "QTorres — Compilador (Front Panel)"
    Purpose: "Compila el Front Panel a código View (movido desde panel.red — 4A refactor)"
]

gen-panel-var-name: func [item /local s fc] [
    s: copy item/name
    if not empty? s [
        fc: uppercase copy/part s 1
        s: rejoin [fc  skip s 1]
    ]
    to-word rejoin ["f" s]
]

gen-indicator-var-name: func [item /local s fc] [
    s: copy item/name
    if not empty? s [
        fc: uppercase copy/part s 1
        s: rejoin [fc  skip s 1]
    ]
    to-word rejoin ["l" s]
]

compile-panel: func [model /local cmds item ctrl-field-name ind-var-name fn ft fval fld-name] [
    cmds: copy []

    foreach item model/front-panel [
        case [
            find [control str-control] item/type [
                ctrl-field-name: gen-panel-var-name item
                append cmds compose [
                    label (item/label/text)
                    (to-set-word ctrl-field-name) field 120 (form item/default)
                    return
                ]
            ]
            item/type = 'bool-control [
                ctrl-field-name: gen-panel-var-name item
                append cmds compose [
                    label (item/label/text)
                    (to-set-word ctrl-field-name) check (item/label/text) (item/default)
                    return
                ]
            ]
            item/type = 'arr-control [
                ind-var-name: gen-indicator-var-name item
                append cmds compose [
                    label (item/label/text)
                    (to-set-word ind-var-name) text 120 (rejoin ["[" form item/default "]"])
                    return
                ]
            ]
            item/type = 'cluster-control [
                foreach [fn ft] fp-cluster-fields item [
                    fld-name: to-word rejoin [form item/name "_" form fn]
                    fval: select any [item/default  copy []] fn
                    append cmds compose [label (rejoin [item/label/text " — " form fn])]
                    case [
                        ft = 'boolean [
                            append cmds compose [
                                (to-set-word fld-name) check (form fn) (any [fval false])
                                return
                            ]
                        ]
                        true [
                            append cmds compose [
                                (to-set-word fld-name) field 120 (form any [fval ""])
                                return
                            ]
                        ]
                    ]
                ]
            ]
            item/type = 'cluster-indicator [
                foreach [fn ft] fp-cluster-fields item [
                    fld-name: to-word rejoin [form item/name "_" form fn]
                    fval: select any [item/default  copy []] fn
                    append cmds compose [
                        label (rejoin [item/label/text " — " form fn])
                        (to-set-word fld-name) text 120 (form any [fval ""])
                        return
                    ]
                ]
            ]
            find [waveform-chart waveform-graph] item/type [
                ind-var-name: gen-indicator-var-name item
                append cmds compose [
                    label (item/label/text)
                    (to-set-word ind-var-name) base 200x160 draw []
                    return
                ]
            ]
            true [
                ind-var-name: gen-indicator-var-name item
                append cmds compose [
                    label (item/label/text)
                    (to-set-word ind-var-name) text 120 (form item/default)
                    return
                ]
            ]
        ]
    ]

    append cmds compose [button "Run" []]
    cmds
]

gen-standalone-code: func [model /local vid-code] [
    vid-code: compile-panel model
    rejoin [
        "Red [title: {QTorres Panel Demo} Needs: 'View]" newline
        "qvi-diagram: []" newline
        "view layout [" newline
        "    " mold vid-code newline
        "]"
    ]
]
