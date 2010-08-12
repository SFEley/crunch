module Crunch
  # An enumerable collection of Fieldset objects with optimizations for rapid loading.
  # Recordsets are _almost_ immutable -- they can be appended to, but they can't ever be
  # removed from, and any given element can only be set once. This corresponds with the
  # MongoDB pattern of retrieving a subset of relevant records and iteratively calling 
  # the GET_MORE operation to finish the set.
  class Recordset
  end
end