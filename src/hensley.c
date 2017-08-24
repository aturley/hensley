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

extern int py_obj_is_none(PyObject *o)
{
  return o == Py_None;
}
