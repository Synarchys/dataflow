
import jsffi

proc genUUID*(): string =
  result = ""
  proc random(): float {.importc: "Math.random".}
  proc floor(n: float): int8 {.importcpp: "Math.floor(#)".} 
  for i in 0..36:
    const adigits = "0123456789abcdef"
    case i:
      of 8, 13, 18, 23:
        result &= "-"
      of 14:
        result &= "4"
      else:
        var r = random() * 16
        result &= adigits[floor(r)]  
