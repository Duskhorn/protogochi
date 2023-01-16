const 
    inhibit_set_locale* = 0x0001
    no_clear_bitmaps* = 0x0002
    no_winch_sighandler* = 0x0004
    no_quit_sighandler* = 0x0008
    preserve_cursor* = 0x0010
    suppress_banners* = 0x0020
    no_alternate_screen* = 0x0040
    no_font_changes* = 0x0080
    drain_input* = 0x0100
    scrolling* = 0x0200
    cli_mode* = no_alternate_screen or no_clear_bitmaps or preserve_cursor or scrolling

type 
    Struct_notcurses = object # original C: struct notcurses
    Struct_ncplane = object 
    Opaque = ptr object

    Egc* = distinct uint32
    Ucs* = distinct uint32

    NcLogLevel* = enum 
        SILENT  
        PANIC   
        FATAL   
        ERROR  
        WARNING
        INFO  
        VERBOSE
        DEBUG 
        TRACE

    NcOptions* = object
        termtype*: cstring
        loglevel*: NcLogLevel
        margin_t*, margin_r*, margin_b*, margin_l*: uint
        flags*: uint64


    NotCurses* = object
        internal: ptr Struct_notcurses 

    NcPlane* = object
        internal: ptr Struct_ncplane

    NcCell* = object
    NcTime* = object

    NcInput* = object
        id*: uint32
        utf8*: array[5,char]

proc libs(): tuple[nc: string, ncf: string] = #TODO: Windows, mac, BSD support
    return (nc: "libnotcurses.so", ncf: "libnotcurses-ffi.so")

const (nc, ncf) = libs()
{. push dynlib: nc .}

proc init(nc: ptr NcOptions, f: File): ptr Struct_notcurses {. importc: "notcurses_init" .}
proc stop(nc: ptr Struct_notcurses): int {. importc: "notcurses_stop", discardable .}

proc stdplane(nc: ptr Struct_notcurses): ptr Struct_ncplane {. importc: "notcurses_stdplane" .}

{. pop dynlib .}
{. push dynlib: ncf .}

proc render(nc: ptr Struct_notcurses): int {. importc: "notcurses_render" .}

proc get_input(nc: ptr Struct_notcurses,time: ptr NcTime, input: ptr NcInput): uint32 {. importc: "notcurses_get".}
proc plane_new(nc: ptr Struct_notcurses, rows, cols, yoff, xoff: int, opaque: Opaque): ptr Struct_ncplane {. importc: "ncplane_new" .}

proc init_cell(cc: ptr NcCell): int {. importc: "nccell_init" .}
proc load_cell(np: ptr Struct_ncplane, cc: ref NcCell, gclust: openarray[char]): int {. importc:"nccell_load" .}
proc load_egc32(np: ptr Struct_ncplane, cc: ref NcCell, egc: Egc): int {. importc:"nccell_load_egc32" .}
proc load_ucs32(np: ptr Struct_ncplane, cc: ref NcCell, n: Ucs): int {. importc:"nccell_load_ucs32" .}

proc put_cell_yx(np: ptr Struct_ncplane, y, x: int, c: ref NcCell): int {. importc: "ncplane_putc_yx" .}
proc put_char_yx(np: ptr Struct_ncplane, y, x: int, c: char): int {. importc:"ncplane_putchar_yx" .}
proc put_egc_yx(np: ptr Struct_ncplane, y, x: int, gclust: openarray[char], sbytes: ptr int): int {. importc:"ncplane_putegc_yx" .}
proc put_string(np: ptr Struct_ncplane, y, x: int, c: cstring): int {. importc: "ncplane_putstr_yx" .}

{. pop dynlib .}

proc get_input*(nc: var Notcurses): tuple[input: NcInput, bytes: uint32] =
    
    result.bytes = nc.internal.get_input(nil, unsafeAddr result.input)


## NotCurses functions

proc newNotCurses*(opts: NcOptions = NcOptions(), file: File = nil): NotCurses =
    result.internal = init(unsafeAddr opts, file)

proc `=destroy`(nc: var NotCurses) =
    stop(nc.internal)

proc render*(nc: NotCurses) = discard nc.internal.render()
## NcPlane functions

proc newPlane*(nc: var NotCurses, rows, cols, yoff, xoff: int): NcPlane = 
    result.internal = nc.internal.plane_new(rows, cols, yoff, xoff, Opaque(nil))

proc stdplane*(nc: NotCurses): NcPlane =
    result.internal = nc.internal.stdplane()

## NcCell functions

proc newCell*(): NcCell =
    var cc: NcCell
    discard init_cell(unsafeAddr cc)
    return cc

proc load_cell*(np: var NcPlane, gclust: openarray[char]): ref NcCell =
    result = new NcCell
    discard np.internal.load_cell(result, gclust)

proc load_cell_egc*(np: var NcPlane, egc: Egc): ref NcCell =
    result = new NcCell
    discard np.internal.load_egc32(result, egc)

proc load_cell_ucs*(np: var NcPlane, ucs: Ucs): ref NcCell =
    result = new NcCell
    discard np.internal.load_ucs32(result, ucs)

proc put_cell*(np: NcPlane, cc: ref NcCell, y: int = -1, x: int = -1) =
    discard np.internal.put_cell_yx(y, x, cc)

## Outputting stuff

proc put_char*(np: NcPlane, c: char, y: int = -1, x: int = -1) =
    discard np.internal.put_char_yx(y, x, c)

proc put_egc*(np: NcPlane, gclust: openarray[char], y: int = -1, x: int = -1): int =
    discard np.internal.put_egc_yx(y, x, gclust, addr result)

proc put_string*(np: NcPlane, s: string, y: int = -1, x: int = -1) =
    discard np.internal.put_string(y, x, s.cstring)


when isMainModule:
    echo "Test libnames: " & nc & " " & ncf