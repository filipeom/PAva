cnt = 0

struct BlockException <: Exception
  name
  value
end

function block(func::Function)
  label = "L$cnt"
  global cnt += 1
  try
    func(label)
  catch e
    if isa(e, BlockException)
      if e.name == label
        return e.value
      else
        rethrow()
      end
    else
      rethrow()
    end
  end
end

function return_from(name, value=nothing)
  throw(BlockException(name, value))
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
