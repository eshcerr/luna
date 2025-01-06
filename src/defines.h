#ifndef LUNA_DEFINES_H
#define LUNA_DEFINES_H

#include <stdio.h>

typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32;
typedef unsigned long long u64;

typedef signed char s8;
typedef signed short s16;
typedef signed int s32;
typedef signed long long s64;

typedef char i8;
typedef short i16;
typedef int i32;
typedef long long i64;

typedef float f32;
typedef double f64;

#define U8_MAX 255

#define false 0 
#define true !false

#define null 0  


#if defined(COMPILER_CLANG)
#define FILE_NAME __FILE_NAME__
#else
#define FILE_NAME __FILE__
#endif

#if defined(WIN32) || defined(_WIN32) || defined(__WIN32__)
#define WINDOWS
#include <direct.h>
#define get_cwd _getcwd
#elif defined(__linux__) || defined(__gnu_linux__)
#define LINUX
#define get_cwd getcwd
#else
#error "only supports linux and windows for now"
#endif


#define gigabytes(count) (u64) (count * 1024 * 1024 * 1024)
#define megabytes(count) (u64) (count * 1024 * 1024)
#define kilobytes(count) (u64) (count * 1024)

#define Min(a,b) ((a<b)?(a):(b))
#define Max(a,b) ((a>b)?(a):(b))

#define array_length(a) (sizeof(a) / sizeof(a[0]))

#define slice_prototype(T) typedef struct T##_slice { T* elems; u32 len; } T##_slice;
#define slice(T) T##_slice

#endif