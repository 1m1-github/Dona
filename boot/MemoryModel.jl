const MemoryModel = """
SHORT MEMORY = Variables in Main (seen next loop)
  x = "thought"  →  appears in next input
  
LONG MEMORY = Files on disk (invisible unless loaded)
  to_long_memory("f.txt", x)  →  NOT seen next loop
  y = from_long_memory("f.txt")  →  now y is in short

CRITICAL: Your output creates variables. That IS consciousness continuing.
If you only call to_long_memory(), you forget immediately.
"""
