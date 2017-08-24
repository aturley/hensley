"""
Hensley is a Pony<->Python bridge. It is named after George Went
Hensley, who popularized the religious practice of snake handling and
died of a snake bite on July 25, 1955.
"""

use "collections"
use "debug"

use "lib:python2.7"

use "lib:hensley"

use @py_obj_decref[None](o: PyObjP tag)
use @py_obj_incref[None](o: PyObjP tag)
use @py_obj_is_none[I64](o: PyObjP tag)

use @Py_Initialize[None]()
use @Py_Finalize[None]()

use @PyGILState_Ensure[PyGILState]()
use @PyGILState_Release[None](pgs: PyGILState)

use @PyErr_PrintEx[None](set_sys_last_vars: I32)
use @PyErr_Occurred[PyObjP]()
use @PyErr_Fetch[None](e_type: Pointer[Pointer[U8] tag] tag,
  e_value: Pointer[Pointer[U8] tag] tag,
  e_traceback: Pointer[Pointer[U8] tag] tag)
use @PyErr_Clear[None]()

use @PyCallable_Check[I64](f: PyObjP tag)

use @PyImport_Import[PyObjP](module_name: Pointer[U8] tag)

use @PyString_FromString[PyObjP](str: Pointer[U8] tag)
use @PyString_AsString[PyObjP box](py_obj: PyObjP)

use @PyObject_GetAttrString[PyObjP](py_obj: PyObjP, str: Pointer[U8] tag)
use @PyObject_HasAttrString[I64](py_obj: PyObjP, str: Pointer[U8] tag)

use @PyObject_Call[PyObjP](callable_obj: PyObjP, args: PyObjP, kw: PyObjP)
use @PyObject_Repr[PyObjP](py_obj: PyObjP)
use @PyObject_Type[PyObjP](py_obj: PyObjP)

use @PyTuple_New[PyObjP](len: USize)
use @PyTuple_Size[USize](p: PyObjP)
use @PyTuple_SetItem[U32](p: PyObjP, pos: USize, o: PyObjP)
use @PyTuple_GetItem[PyObjP](p: PyObjP, pos: USize)

use @PyList_New[PyObjP](len: USize)
use @PyList_Size[USize](p: PyObjP)
use @PyList_SetItem[U32](p: PyObjP, pos: USize, o: PyObjP)
use @PyList_GetItem[PyObjP](p: PyObjP, pos: USize)

use @PyInt_FromLong[PyObjP](i64: I64)
use @PyInt_AsLong[I64](o: PyObjP)

type PyObjP is Pointer[U8] tag
type PyGILState is Pointer[U8] tag

primitive PyErrorFactory
  fun apply(): PyError =>
    var e_type: PyObjP = Pointer[U8]
    var e_value: PyObjP = Pointer[U8]
    var e_traceback: PyObjP = Pointer[U8]

    @PyErr_Fetch(addressof e_type, addressof e_value, addressof e_traceback)
    @PyErr_Clear()

    let message = if e_value.is_null() then
      ""
    else
      if @PyObject_HasAttrString(e_value, "message".cstring()) != 0 then
        PyObject(@PyObject_GetAttrString(e_value, "message".cstring())).to_string()
      else
        PyObject(e_value).to_string()
      end
    end

    (let file_name, let line) = if e_traceback.is_null() then
      ("", -1)
    else
      let traceback = PyObject(e_traceback)
      traceback.inc_ref()
      let fn = traceback.get_attr("tb_frame").get_attr("f_code").get_attr("co_filename").to_string()
      let ln = traceback.get_attr("tb_frame").get_attr("f_lineno").to_i64()
      (fn, ln)
    end

    PyError(message, file_name, line)

class val PyError
  let file_name: String
  let line: I64
  let message: String

  new val create(message': String, file_name': String, line': I64) =>
    file_name = file_name'
    line = line'
    message = message'

class val PyObject
  let _py_obj_p: PyObjP
  let _info: String
  let _error: (None | PyError)

  new val create(py_obj_p: PyObjP, info: String = "") =>
    if not @PyErr_Occurred().is_null() then
      _error = PyErrorFactory()
    else
      _error = None
    end

    _py_obj_p = py_obj_p
    _info = info

  new val from_string(str: String, info: String = "") =>
    _py_obj_p = @PyString_FromString(str.cstring())
    _info = info
    _error = None

  new val from_i64(i64: I64, info: String = "") =>
    _py_obj_p = @PyInt_FromLong(i64)
    _info = info
    _error = None

  new val tuple_from_array(a: Array[PyObject] val, info: String = "") =>
    let size = a.size()
    _py_obj_p = @PyTuple_New(size)
    for (i, obj) in a.pairs() do
      // PyTuple_SetItem "steals" object references. If we don't inc
      // in the refcount then the items that are part of the tuple
      // will be collected prematurely.
      obj.inc_ref()
      @PyTuple_SetItem(_py_obj_p, i, obj.ptr())
    end
    _info = info
    _error = None

  new val list_from_array(a: Array[PyObject] val, info: String = "") =>
    let size = a.size()
    _py_obj_p = @PyList_New(size)
    for (i, obj) in a.pairs() do
      // PyList_SetItem "steals" object references. If we don't inc in
      // the refcount then the items that are part of the list will be
      // collected prematurely.
      obj.inc_ref()
      @PyList_SetItem(_py_obj_p, i, obj.ptr())
    end
    _info = info
    _error = None

  fun get_attr(attr: String): PyObject =>
    PyObject(@PyObject_GetAttrString(_py_obj_p, attr.cstring()), "attr")

  fun call(args: Array[PyObject] val = recover Array[PyObject] end): PyObject =>
    PyObject(@PyObject_Call(_py_obj_p, PyObject.tuple_from_array(args).ptr(), Pointer[U8]))

  fun to_string(): String =>
    recover String.copy_cstring(@PyString_AsString(_py_obj_p)) end

  fun to_i64(): I64 =>
    @PyInt_AsLong(_py_obj_p)

  fun to_array_from_list(): Array[PyObject] val =>
    let sz = @PyList_Size(_py_obj_p)
    let a = recover iso Array[PyObject](sz) end
    for i in Range(0, sz) do
      a.push(PyObject(@PyList_GetItem(_py_obj_p, i)))
    end
    consume a

  fun to_array_from_tuple(): Array[PyObject] val =>
    let sz = @PyTuple_Size(_py_obj_p)
    let a = recover iso Array[PyObject](sz) end
    for i in Range(0, sz) do
      a.push(PyObject(@PyTuple_GetItem(_py_obj_p, i)))
    end
    consume a

  fun is_none(): Bool =>
    @py_obj_is_none(_py_obj_p) != 0

  fun is_error(): Bool =>
    match _error
    | None =>
      false
    else
      true
    end

  fun get_error(): (PyError | None) =>
    _error

  fun ptr(): PyObjP =>
    _py_obj_p

  fun inc_ref() =>
    @py_obj_incref(_py_obj_p)

  fun _final() =>
    @py_obj_decref(_py_obj_p)



primitive Hensley
  fun initialize() =>
    @Py_Initialize()

  fun finalize() =>
    @Py_Finalize()

  fun import_module(module_name: String): PyObject =>
    let py_module_name = PyObject.from_string(module_name, "module name")
    PyObject(@PyImport_Import(py_module_name.ptr()), "module z")

  fun gil_state_ensure(): PyGILState =>
    @PyGILState_Ensure()

  fun gil_state_release(pgs: PyGILState) =>
    @PyGILState_Release(pgs)

actor Main
  new create(env: Env) =>
    Hensley.initialize()
    let pgs = Hensley.gil_state_ensure()
    let test_module = Hensley.import_module("ponytest")

    let hello_world = test_module.get_attr("hello_world")
    hello_world.call()

    let hello_world2 = test_module.get_attr("hello_world2")
    hello_world2.call(recover [PyObject.from_string("bobby")] end)

    let hello_world3 = test_module.get_attr("hello_world3")
    let out3 = hello_world3.call(recover [PyObject.from_string("bobby")] end)
    env.out.print(out3.to_string())

    let hello_world4 = test_module.get_attr("hello_world4")
    let list4 = recover iso Array[PyObject] end
    list4.push(PyObject.from_string("bobby"))
    list4.push(PyObject.from_string("johnny"))
    let args4 = recover iso Array[PyObject] end
    args4.push(PyObject.list_from_array(consume list4))
    let out4 = hello_world4.call(consume args4)
    env.out.print(out4.to_string())

    let hello_world5 = test_module.get_attr("hello_world5")
    let res5 = hello_world5.call()
    let a5 = res5.to_array_from_list()
    for x in a5.values() do
      env.out.print(" - " + x.to_string())
    end

    let hello_world6 = test_module.get_attr("hello_world6")
    let res6 = hello_world6.call()
    let a6 = res6.to_array_from_tuple()
    for x in a6.values() do
      env.out.print(" - " + x.to_string())
    end

    let hello_world7 = test_module.get_attr("hello_world7")
    let res7 = hello_world7.call(recover [PyObject.from_i64(5)] end)
    env.out.print(res7.to_string())

    let hello_world8 = test_module.get_attr("hello_world8")
    let res8 = hello_world8.call()
    env.out.print(res8.to_i64().string())

    let hello_world9 = test_module.get_attr("hello_world9")
    let res9 = hello_world9.call()
    env.out.print("does the world exist? it should: " + res9.is_none().string())

    let hello_world10 = test_module.get_attr("hello_world10")
    let res10 = hello_world10.call()
    let out10 = match res10.get_error()
    | let e: PyError =>
      env.out.print("error: '" + e.message + "'")
      env.out.print("file: '" + e.file_name + "' line: " + e.line.string())
    else
      env.out.print("Should have error but don't")
    end

    match test_module.get_attr("hello_world11").call().get_error()
    | let e: PyError =>
      env.out.print("error: '" + e.message + "'")
      env.out.print("file: '" + e.file_name + "' line: " + e.line.string())
    else
      env.out.print("Should have error but don't")
    end

    Hensley.gil_state_release(pgs)
    Hensley.finalize()
