#=
Copyright (c) 2016 Saurav Sachidanand

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
=#

module CBOR

include("constants.jl")
include("encoding-common.jl")
include("decoding-common.jl")

export encode
export decode, decode_with_iana
export Simple, Null, Undefined

# ------- straightforward decoding for usual Julia types

function decode(cbor_bytes::Array{UInt8, 1})
    data, _ = decode_next(1, cbor_bytes, false)
    return data
end

function decode_with_iana(cbor_bytes::Array{UInt8, 1})
    warn("Results from decode_with_iana may change in the future.")
    data, _ = decode_next(1, cbor_bytes, true)
    return data
end

# ------- straightforward encoding for usual Julia types

function encode(bool::Bool)
    return UInt8[CBOR_FALSE_BYTE + bool]
end

function encode(num::Unsigned)
    encode_unsigned_with_type(TYPE_0, num)
end

function encode(num::Signed)
    if num < 0
        return encode_unsigned_with_type(TYPE_1, Unsigned(-num - 1) )
    else
        return encode_unsigned_with_type(TYPE_0, Unsigned(num))
    end
end

function encode(bytes::AbstractVector{UInt8})
    return UInt8[encode_unsigned_with_type(TYPE_2, Unsigned(length(bytes)) );
                 bytes]
end

function encode(string::Union{UTF8String, ASCIIString})
    return UInt8[encode_unsigned_with_type(TYPE_3, Unsigned(sizeof(string)) );
                 string.data]
end

function encode(list::Union{AbstractVector, Tuple})
    cbor_bytes = encode_unsigned_with_type(TYPE_4, Unsigned(length(list)) )
    for e in list
        append!(cbor_bytes, encode(e))
    end
    return cbor_bytes
end

function encode(map::Associative)
    cbor_bytes = encode_unsigned_with_type(TYPE_5, Unsigned(length(map)) )
    for (key, value) in map
        append!(cbor_bytes, encode(key))
        append!(cbor_bytes, encode(value))
    end
    return cbor_bytes
end

function encode(big_int::BigInt)
    hex_str, tag =
        if big_int < 0
            hex(-big_int - 1), NEG_BIG_INT_TAG
        else
            hex(big_int), POS_BIG_INT_TAG
        end
    if isodd(length(hex_str))
        hex_str = "0" * hex_str
    end
    return UInt8[encode_unsigned_with_type(TYPE_6, Unsigned(tag));
                 encode(hex2bytes(hex_str))]
end

function encode(float::Union{Float64, Float32, Float16})
    flt, addntl_info =
        if sizeof(float) == SIZE_OF_FLOAT64
            if float == Float32(float)
                Float32(float), ADDNTL_INFO_FLOAT32
            else
                float, ADDNTL_INFO_FLOAT64
            end
        elseif sizeof(float) == SIZE_OF_FLOAT32
            float, ADDNTL_INFO_FLOAT32
        else
            warn("Decoding 16-bit floats isn't supported.")
            float, ADDNTL_INFO_FLOAT16
        end
    return UInt8[TYPE_7 | addntl_info; hex2bytes(num2hex(flt))]
end


# ------- encoding for indefinite length collections

function encode_indef_length_collection(producer::Task, collection_type)
    const typ =
        if collection_type <: AbstractVector{UInt8}
            TYPE_2
        elseif collection_type <: Union{UTF8String, ASCIIString}
            TYPE_3
        elseif collection_type <: Union{AbstractVector, Tuple}
            TYPE_4
        elseif collection_type <: Associative
            TYPE_5
        else
            error(@sprintf "Collection type %s is not supported for indefinite length encoding." collection_type)
        end

    cbor_bytes = UInt8[typ | ADDNTL_INFO_INDEF]

    count = 0
    for e in producer
        append!(cbor_bytes, encode(e))
        count += 1
    end

    if typ == TYPE_5 && isodd(count)
        error(@sprintf "Collection type %s requires an even number of input data items in order to be consistent." collection_type)
    end

    push!(cbor_bytes, BREAK_INDEF)
    return cbor_bytes
end

# ------- encoding with tags

function encode_with_tag(tag::Unsigned, data)
    return UInt8[encode_unsigned_with_type(TYPE_6, tag); encode(data)]
end

# ------- encoding for user-defined types

function encode(data)
    encode_custom_type(data)
end

function encode_custom_type(data)
    type_map = Dict{UTF8String, Any}("type" => string(typeof(data)) )
    for f in fieldnames(data)
        type_map[string(f)] = data.(f)
    end
    encode(type_map)
end

# ------- dispatching for Pairs

function encode(pair::Pair)
    if typeof(pair.first) <: Integer && pair.first >= 0
        encode_with_tag(Unsigned(pair.first), pair.second)
    elseif typeof(pair.first) == Task
        encode_indef_length_collection(pair.first, pair.second)
    else
        encode_custom_type(pair)
    end
end

# ------- encoding for Simple types

type Simple
    val::UInt8
end

Base.isequal(a::Simple, b::Simple) = Base.isequal(a.val, b.val)

function encode(simple::Simple)
    encode_unsigned_with_type(TYPE_7, simple.val)
end

# ------- encoding for Null and Undefined

type Null
end

type Undefined
end

function encode(null::Null)
    return UInt8[CBOR_NULL_BYTE]
end

function encode(undef::Undefined)
    return UInt8[CBOR_UNDEF_BYTE]
end

end
