using Test

tests = [
   """a=1""" =>  """a=1""",
   """a=1\n```julia\nx=1\n```""" =>  """#a=1\nx=1""",
   """a=1\n```julia\nx=1\n```b=1""" =>  """#a=1\nx=1\n#b=1""",
   """```julia\nx=1\n```""" =>  """x=1""",
   """```julia\nx=1\n```b=1""" =>  """x=1\n#b=1""",
   """a=1```julia\nx=1\n```b=1```julia\ny=1\n```c=1""" =>  """#a=1\nx=1\n#b=1\ny=1\n#c=1""",
   """```julia\nx=1\n```b=1```julia\ny=1\n```c=1""" =>  """x=1\n#b=1\ny=1\n#c=1""",
   """a=1```julia\nx=1\n```b=1```julia\ny=1\n```c=1""" =>  """#a=1\nx=1\n#b=1\ny=1\n#c=1""",
   """a=1```julia\nx=1\n``````julia\ny=1\n```c=1""" =>  """#a=1\nx=1\ny=1\n#c=1""",
   """a=1```julia\nx=1\n```b=1```julia\ny=1\n```""" =>  """#a=1\nx=1\n#b=1\ny=1""",
   """a=1```julia\nx=1\n```b=1\nd=1```julia\ny=1\n```c=1""" =>  """#a=1\nx=1\n#b=1\n#d=1\ny=1\n#c=1""",
   """\na=1\ne=1\n```julia\n\nx=1\n```\nb=1\nd=1\n```julia\ny=1\n```\nc=1\nf=1\n""" =>  """#a=1\n#e=1\nx=1\n#b=1\n#d=1\ny=1\n#c=1\n#f=1""",
]

for i = eachindex(tests)
    test = tests[i]
    @show i, test
    @test extract_julia_blocks(test[1]) == test[2]
end