const TYPE_0 = zero(UInt8)
const TYPE_1 = one(UInt8) << 5
const TYPE_2 = UInt8(2) << 5
const TYPE_3 = UInt8(3) << 5
const TYPE_4 = UInt8(4) << 5
const TYPE_5 = UInt8(5) << 5
const TYPE_6 = UInt8(6) << 5
const TYPE_7 = UInt8(7) << 5

const TYPE_BITS_MASK = UInt8(0b1110_0000)
const ADDNTL_INFO_MASK = UInt8(0b0001_1111)

const ADDNTL_INFO_UINT8 = UInt8(24)
const ADDNTL_INFO_UINT16 = UInt8(25)
const ADDNTL_INFO_UINT32 = UInt8(26)
const ADDNTL_INFO_UINT64 = UInt8(27)

const ADDNTL_INFO_FLOAT16 = UInt8(25)
const ADDNTL_INFO_FLOAT32 = UInt8(26)
const ADDNTL_INFO_FLOAT64 = UInt8(27)

const ADDNTL_INFO_INDEF = UInt8(31)
const BREAK_TAG = TYPE_7 | 31

const SINGLE_BYTE_UINT_PLUS_ONE = 24
const UINT8_MAX_PLUS_ONE = 0x100
const UINT16_MAX_PLUS_ONE = 0x10000
const UINT32_MAX_PLUS_ONE = 0x100000000
const UINT64_MAX_PLUS_ONE = 0x10000000000000000

const POS_BIG_INT_TAG = UInt8(2)
const NEG_BIG_INT_TAG = UInt8(3)

const BITS_PER_BYTE = UInt8(8)
const HEX_BASE = UInt8(16)
const LOWEST_ORDER_BYTE_MASK = 0xFF

const SIZE_OF_FLOAT64 = sizeof(Float64)
const SIZE_OF_FLOAT32 = sizeof(Float32)
const SIZE_OF_FLOAT16 = sizeof(Float16)

const CBOR_TRUE_BYTE = UInt8(0xf5)
const CBOR_FALSE_BYTE = UInt8(0xf4)
