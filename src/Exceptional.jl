cnt = 0

struct BlockException <: Exception
  lbl 
  val
end

function block(func::Function)
  lbl = "L$cnt"
  global cnt += 1
  try
    func(lbl)
  catch e
    if isa(e, BlockException)
      if e.lbl == lbl
        return e.val
      else
        rethrow()
      end
    else
      rethrow()
    end
  end
end

function return_from(lbl, val=nothing)
  throw(BlockException(lbl, val))
end

function available_restarts(name, args...)
  # do something end
end

function restart_bind(func, restarts...)
  # do something
end

function error(exception::Exception)
  # do something
end

function handler_bind(func, handlers...)
  # do something
end
