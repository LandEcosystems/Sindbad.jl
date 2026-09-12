# SINDBAD Array Handling Functions

This document describes the array handling functions available in SINDBAD, which are designed to optimize performance and maintain consistency across the framework. These functions are implemented in `src/utilsCore.jl` as they are accessed within SINDBAD models..

## Overview

SINDBAD provides several specialized array handling functions that are optimized for performance and memory efficiency. These functions are particularly useful when working with large datasets and model outputs.

## Core Array Functions

### `repElem`
Replace an element of a vector or static vector with a new value. This function is optimized for performance by avoiding unnecessary array copies.

```julia
v = [1.0, 2.0, 3.0]
v = repElem(v, 10.0, 2)  # Replace the second element with 10.0
```

### `@rep_elem` Macro
A macro that simplifies replacing elements in vectors defined in `land.pools`. The macro expands to a `repElem` call during compilation.

```julia
@rep_elem pout[l] ⇒ (cEco, lc)
```

::: info
You can inspect the macro expansion using:
```julia
@macroexpand @rep_elem pout[l] ⇒ (cEco, lc)
```
:::

### `addToElem`
Add a value to a specific element of a vector or static vector. This function is optimized for in-place modifications.

```julia
v = [1.0, 2.0, 3.0]
v = addToElem(v, 5.0, nothing, 2)  # Add 5.0 to the second element
```

### `@add_to_elem` Macro
A macro that simplifies adding values to elements in vectors defined in `land.pools`. The macro expands to an `addToElem` call during compilation.

```julia
@add_to_elem -evaporation ⇒ (ΔsoilW, 1, :soilW)
```

### `addVec`
Add two vectors element-wise. This function is optimized for vectorized operations.

### `repVec`
Replace the values of a vector with a new vector. Also available as the `@rep_vec` macro for vectors in `land.pools`.

### `cumulative_sum!`
Compute the cumulative sum of elements in an input vector and store the result in an output vector. This function is optimized for in-place operations.

### `safe_divide`
Return either a ratio or numerator depending on whether the denominator is zero. This function is useful for handling division operations safely.

### `getZix`
A helper function to get the indices of certain components (e.g., cVeg) within a larger vector of ecosystem pools (e.g., cEco).

## Performance Considerations

1. **Memory Efficiency**
   - Functions like `repElem` and `addToElem` avoid unnecessary array copies
   - In-place operations are used where possible (e.g., `cumulative_sum!`)
   - Views are created instead of copies when appropriate

2. **Vectorization**
   - Operations are vectorized where possible
   - Specialized for common array operations
   - Optimized for both small and large arrays

3. **Type Stability**
   - Functions maintain type stability
   - Support both static and dynamic arrays
   - Handle different numeric types efficiently

## Best Practices

1. **Use Macros for Land Pools**
   - Prefer `@rep_elem` and `@add_to_elem` for `land.pools` operations
   - Macros provide compile-time optimization
   - Ensure type safety and consistency

2. **In-Place Operations**
   - Use in-place operations (functions ending with `!`) when possible
   - Reduces memory allocation
   - Improves performance for large arrays

3. **Vectorized Operations**
   - Use vectorized operations instead of loops
   - Take advantage of SIMD instructions
   - Better performance for large datasets

4. **Type Annotations**
   - Provide type annotations when possible
   - Helps compiler optimize code
   - Improves type stability

## Example Usage

```julia
# Efficient element replacement
v = [1.0, 2.0, 3.0]
v = repElem(v, 10.0, 2)

# In-place cumulative sum
v = [1.0, 2.0, 3.0]
out = similar(v)
cumulative_sum!(out, v)

# Safe division
numerator = 10.0
denominator = 2.0
result = safe_divide(numerator, denominator)

# Component indexing
cEco = [1.0, 2.0, 3.0, 4.0, 5.0]
cVeg_indices = getZix(cEco, :cVeg)
```
