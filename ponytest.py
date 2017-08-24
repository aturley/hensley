print "hello"

def hello_world():
    print "hello world"

def hello_world2(name):
    print "hello world 2,", name

def hello_world3(name):
    return "hello world 3, " + name

def hello_world4(names):
    return "hello " + " and ".join(names)

def hello_world5():
    return ["hello", "world"]

def hello_world6():
    return ("hello", "world")

def hello_world7(times):
    return "hello world" * times

def hello_world8():
    return len("hello world")

def hello_world9():
    return None

def hello_world10():
    # ball = [1]
    # ball[2]
    raise Exception("this is an exception")

def hello_world11():
    ball = [1]
    ball[2]
