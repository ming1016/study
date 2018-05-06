def foo(responses, m)
    responses[0].each { |k,v| m[k] = v }
end
