#ifdef __APPLE__
    #include <Python/Python.h>
#else
    #include <python2.7/Python.h>
#endif

extern void py_obj_decref(PyObject *o)
{
  Py_DECREF(o);
}

extern void py_obj_incref(PyObject *o)
{
  Py_INCREF(o);
}

extern PyObject *py_none()
{
  return Py_None;
}

extern int py_string_check(PyObject *o)
{
  return PyString_Check(o);
}

extern int py_obj_is_none(PyObject *o)
{
  return o == Py_None;
}
