struct BlockException <: Exception
  name
  value
end

function block(func::Function)
  name = "testing"
  try
    func(name)
  catch e
    if isa(e, BlockException)
      return e.value
    end
  end
end

function return_from(name, value=nothing)
  throw(BlockException(name, value))
end

function available_restarts(name, args...)
  # do something
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
