#===--- CMakeLists.txt - Concurrency support library ---------------------===#
#
# This source file is part of the Swift.org open source project
#
# Copyright (c) 2019 - 2020 Apple Inc. and the Swift project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See https://swift.org/LICENSE.txt for license information
# See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
#
#===----------------------------------------------------------------------===#

set(SWIFT_RUNTIME_CONCURRENCY_C_FLAGS)
set(SWIFT_RUNTIME_CONCURRENCY_SWIFT_FLAGS -I${CMAKE_CURRENT_SOURCE_DIR}/InternalShims)

set(swift_concurrency_private_link_libraries)
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
  list(APPEND swift_concurrency_private_link_libraries
    Synchronization
    mincore.lib # For QueryInterruptTime()
  )
endif()

set(swift_concurrency_incorporate_object_libraries_so swiftThreading)

if("${SWIFT_CONCURRENCY_GLOBAL_EXECUTOR}" STREQUAL "dispatch")
  if(NOT CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    include_directories(AFTER
                          ${SWIFT_PATH_TO_LIBDISPATCH_SOURCE})

    # FIXME: we can't rely on libdispatch having been built for the
    # target at this point in the process.  Currently, we're relying
    # on soft-linking.
    list(APPEND swift_concurrency_link_libraries
      dispatch)
  endif()
elseif("${SWIFT_CONCURRENCY_GLOBAL_EXECUTOR}" STREQUAL "singlethreaded" OR
       "${SWIFT_CONCURRENCY_GLOBAL_EXECUTOR}" STREQUAL "hooked" OR
       "${SWIFT_CONCURRENCY_GLOBAL_EXECUTOR}" STREQUAL "none")
  list(APPEND SWIFT_RUNTIME_CONCURRENCY_C_FLAGS
    "-DSWIFT_CONCURRENCY_ENABLE_DISPATCH=0")
else()
  message(FATAL_ERROR "Invalid value for SWIFT_CONCURRENCY_GLOBAL_EXECUTOR (\"${SWIFT_CONCURRENCY_GLOBAL_EXECUTOR}\").")
endif()

if(NOT swift_concurrency_async_fp_mode)
  set(swift_concurrency_async_fp_mode "always")
endif()

# Don't emit extended frame info on platforms other than darwin, system
# backtracer and system debugger are unlikely to support it.
if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
  list(APPEND SWIFT_RUNTIME_CONCURRENCY_C_FLAGS
    "-fswift-async-fp=${swift_concurrency_async_fp_mode}")
  list(APPEND SWIFT_RUNTIME_CONCURRENCY_SWIFT_FLAGS
    "-Xfrontend"
    "-swift-async-frame-pointer=${swift_concurrency_async_fp_mode}")
else()
  list(APPEND SWIFT_RUNTIME_CONCURRENCY_C_FLAGS "-fswift-async-fp=never")
endif()

# Do not remove until IsolatedAny is on by default in all supported compilers.
list(APPEND SWIFT_RUNTIME_CONCURRENCY_SWIFT_FLAGS
  "-enable-experimental-feature"
  "IsolatedAny"
  )

list(APPEND SWIFT_RUNTIME_CONCURRENCY_SWIFT_FLAGS "-strict-memory-safety")
list(APPEND SWIFT_RUNTIME_CONCURRENCY_SWIFT_FLAGS "-enable-experimental-feature" "AllowUnsafeAttribute")

list(APPEND SWIFT_RUNTIME_CONCURRENCY_SWIFT_FLAGS "-enable-experimental-feature" "Extern")

list(APPEND SWIFT_RUNTIME_CONCURRENCY_C_FLAGS
  "-D__STDC_WANT_LIB_EXT1__=1")

set(SWIFT_RUNTIME_CONCURRENCY_C_SOURCES
  ../CompatibilityOverride/CompatibilityOverride.cpp
  Actor.cpp
  AsyncLet.cpp
  Clock.cpp
  GlobalExecutor.cpp
  ConcurrencyHooks.cpp
  EmbeddedSupport.cpp
  Error.cpp
  ExecutorBridge.cpp
  ExecutorChecks.cpp
  Setup.cpp
  Task.cpp
  TaskAlloc.cpp
  TaskStatus.cpp
  TaskGroup.cpp
  TaskLocal.cpp
  ThreadingError.cpp
  TracingSignpost.cpp
  AsyncStream.cpp
  linker-support/magic-symbols-for-install-name.c
)

set(SWIFT_RUNTIME_CONCURRENCY_SWIFT_SOURCES
  Actor.swift
  AsyncLet.swift
  CheckedContinuation.swift
  Errors.swift
  Executor.swift
  ExecutorBridge.swift
  ExecutorAssertions.swift
  AsyncCompactMapSequence.swift
  AsyncDropFirstSequence.swift
  AsyncDropWhileSequence.swift
  AsyncFilterSequence.swift
  AsyncFlatMapSequence.swift
  AsyncIteratorProtocol.swift
  AsyncMapSequence.swift
  AsyncPrefixSequence.swift
  AsyncPrefixWhileSequence.swift
  AsyncSequence.swift
  AsyncThrowingCompactMapSequence.swift
  AsyncThrowingDropWhileSequence.swift
  AsyncThrowingFilterSequence.swift
  AsyncThrowingFlatMapSequence.swift
  AsyncThrowingMapSequence.swift
  AsyncThrowingPrefixWhileSequence.swift
  PartialAsyncTask.swift
  GlobalActor.swift
  GlobalConcurrentExecutor.swift
  MainActor.swift
  PriorityQueue.swift
  SourceCompatibilityShims.swift
  Task.swift
  Task+PriorityEscalation.swift
  Task+TaskExecutor.swift
  TaskCancellation.swift
  TaskGroup.swift
  DiscardingTaskGroup.swift
  TaskLocal.swift
  TaskSleep.swift
  AsyncStreamBuffer.swift
  AsyncStream.swift
  AsyncThrowingStream.swift
  Deque/_DequeBuffer.swift
  Deque/_DequeBufferHeader.swift
  Deque/_DequeSlot.swift
  Deque/_UnsafeWrappedBuffer.swift
  Deque/Compatibility.swift
  Deque/Deque+Storage.swift
  Deque/Deque+UnsafeHandle.swift
  Deque/Deque.swift
  Deque/Deque+Codable.swift
  Deque/Deque+Collection.swift
  Deque/Deque+CustomDebugStringConvertible.swift
  Deque/Deque+CustomReflectable.swift
  Deque/Deque+CustomStringConvertible.swift
  Deque/Deque+Equatable.swift
  Deque/Deque+ExpressibleByArrayLiteral.swift
  Deque/Deque+Extras.swift
  Deque/Deque+Hashable.swift
  Deque/Deque+Testing.swift
  Deque/UnsafeMutableBufferPointer+Utilities.swift
  Clock.swift
  ContinuousClock.swift
  SuspendingClock.swift
  TaskSleepDuration.swift
  UnimplementedExecutor.swift
  CooperativeExecutor.swift
  PlatformExecutorDarwin.swift
  PlatformExecutorLinux.swift
  PlatformExecutorWindows.swift
  PlatformExecutorOpenBSD.swift
  PlatformExecutorFreeBSD.swift
)

set(SWIFT_RUNTIME_CONCURRENCY_NONEMBEDDED_C_SOURCES
  ExecutorImpl.cpp
)

set(SWIFT_RUNTIME_CONCURRENCY_EXECUTOR_SOURCES)
set(SWIFT_RUNTIME_CONCURRENCY_NONEMBEDDED_SWIFT_SOURCES)

if("${SWIFT_CONCURRENCY_GLOBAL_EXECUTOR}" STREQUAL "dispatch")
  set(SWIFT_RUNTIME_CONCURRENCY_EXECUTOR_SOURCES
    DispatchGlobalExecutor.cpp
  )
  set(SWIFT_RUNTIME_CONCURRENCY_NONEMBEDDED_SWIFT_SOURCES
    DispatchExecutor.swift
    CFExecutor.swift
    ExecutorImpl.swift
  )
elseif("${SWIFT_CONCURRENCY_GLOBAL_EXECUTOR}" STREQUAL "singlethreaded")
  set(SWIFT_RUNTIME_CONCURRENCY_NONEMBEDDED_SWIFT_SOURCES
    ExecutorImpl.swift
    PlatformExecutorCooperative.swift
    )
else()
  set(SWIFT_RUNTIME_CONCURRENCY_NONEMBEDDED_SWIFT_SOURCES
    ExecutorImpl.swift
    PlatformExecutorNone.swift
  )
endif()

set(SWIFT_RUNTIME_CONCURRENCY_EMBEDDED_SWIFT_SOURCES
  PlatformExecutorNone.swift
  )

set(LLVM_OPTIONAL_SOURCES
  DispatchGlobalExecutor.cpp
  CooperativeGlobalExecutor.cpp
  DispatchGlobalExecutor.cpp
)

set(SWIFT_CONCURRENCY_DEPENDENCIES)
if((SWIFT_BUILD_CLANG_OVERLAYS
    OR SWIFT_BUILD_TEST_SUPPORT_MODULES)
   AND (NOT DEFINED SWIFT_BUILD_CLANG_OVERLAYS_SKIP_BUILTIN_FLOAT
        OR NOT SWIFT_BUILD_CLANG_OVERLAYS_SKIP_BUILTIN_FLOAT))
  set(SWIFT_CONCURRENCY_DEPENDENCIES _Builtin_float)
endif()
set(SWIFT_CONCURRENCY_GYB_SOURCES
  Task+init.swift.gyb
  TaskGroup+addTask.swift.gyb
  Task+immediate.swift.gyb)

# Build with a minimum deployment target of 10.15
if(SWIFT_DARWIN_DEPLOYMENT_VERSION_OSX VERSION_LESS "10.15")
  set(osx_deployment_target "10.15")
else()
  set(osx_deployment_target "${SWIFT_DARWIN_DEPLOYMENT_VERSION_OSX}")
endif()

add_swift_target_library(swift_Concurrency ${SWIFT_STDLIB_LIBRARY_BUILD_TYPES} IS_STDLIB
  ${SWIFT_RUNTIME_CONCURRENCY_C_SOURCES}
  ${SWIFT_RUNTIME_CONCURRENCY_EXECUTOR_SOURCES}
  ${SWIFT_RUNTIME_CONCURRENCY_NONEMBEDDED_C_SOURCES}
  ${SWIFT_RUNTIME_CONCURRENCY_SWIFT_SOURCES}
  ${SWIFT_RUNTIME_CONCURRENCY_NONEMBEDDED_SWIFT_SOURCES}

  GYB_SOURCES
    ${SWIFT_CONCURRENCY_GYB_SOURCES}

  SWIFT_MODULE_DEPENDS ${SWIFT_CONCURRENCY_DEPENDENCIES}
  SWIFT_MODULE_DEPENDS_ANDROID Android
  SWIFT_MODULE_DEPENDS_LINUX Glibc
  SWIFT_MODULE_DEPENDS_LINUX_STATIC Musl
  SWIFT_MODULE_DEPENDS_FREEBSD Glibc
  SWIFT_MODULE_DEPENDS_OPENBSD Glibc
  SWIFT_MODULE_DEPENDS_CYGWIN Glibc
  SWIFT_MODULE_DEPENDS_HAIKU Glibc
  SWIFT_MODULE_DEPENDS_WINDOWS CRT

  PRIVATE_LINK_LIBRARIES ${swift_concurrency_private_link_libraries}
  INCORPORATE_OBJECT_LIBRARIES_SHARED_ONLY
    ${swift_concurrency_incorporate_object_libraries_so}
  LINK_LIBRARIES ${swift_concurrency_link_libraries}

  DEPLOYMENT_VERSION_OSX ${osx_deployment_target}

  C_COMPILE_FLAGS
    -Dswift_Concurrency_EXPORTS ${SWIFT_RUNTIME_CONCURRENCY_C_FLAGS}
    -I${SWIFT_SOURCE_DIR}/stdlib/include
  SWIFT_COMPILE_FLAGS
    ${SWIFT_STANDARD_LIBRARY_SWIFT_FLAGS}
    -parse-stdlib
    ${SWIFT_RUNTIME_CONCURRENCY_SWIFT_FLAGS}
  ${swift_concurrency_options}
  LINK_FLAGS "${SWIFT_RUNTIME_SWIFT_LINK_FLAGS}"
  INSTALL_IN_COMPONENT stdlib
  MACCATALYST_BUILD_FLAVOR zippered
)

# Embedded Swift Concurrency library
set(SWIFT_SHOULD_BUILD_EMBEDDED_CONCURRENCY TRUE)
is_build_type_optimized("${SWIFT_STDLIB_BUILD_TYPE}" swift_optimized)
if(NOT swift_optimized)
  set(SWIFT_SHOULD_BUILD_EMBEDDED_CONCURRENCY FALSE)
elseif(BOOTSTRAPPING_MODE STREQUAL "OFF")
  set(SWIFT_SHOULD_BUILD_EMBEDDED_CONCURRENCY FALSE)
elseif(SWIFT_HOST_VARIANT STREQUAL "windows") # For now, don't build embedded Concurrency on Windows
  set(SWIFT_SHOULD_BUILD_EMBEDDED_CONCURRENCY FALSE)
endif()
if(SWIFT_SHOULD_BUILD_EMBEDDED_STDLIB AND SWIFT_SHOULD_BUILD_EMBEDDED_CONCURRENCY)
  add_custom_target(embedded-concurrency)
  add_dependencies(embedded-libraries embedded-concurrency)

  set(SWIFT_ENABLE_REFLECTION OFF)
  set(SWIFT_STDLIB_SUPPORT_BACK_DEPLOYMENT OFF)
  set(SWIFT_STDLIB_STABLE_ABI OFF)
  set(SWIFT_STDLIB_ENABLE_OBJC_INTEROP OFF)
  set(SWIFT_CONCURRENCY_USES_DISPATCH FALSE)
  set(SWIFT_STDLIB_SINGLE_THREADED_CONCURRENCY TRUE)
  set(SWIFT_STDLIB_CONCURRENCY_TRACING FALSE)
  set(SWIFT_STDLIB_HAS_ENVIRON FALSE)
  set(SWIFT_STDLIB_HAS_ASL FALSE)
  list(APPEND LLVM_OPTIONAL_SOURCES ExecutorImpl.cpp)

  foreach(entry ${EMBEDDED_STDLIB_TARGET_TRIPLES})
    string(REGEX REPLACE "[ \t]+" ";" list "${entry}")
    list(GET list 0 arch)
    list(GET list 1 mod)
    list(GET list 2 triple)

    set(extra_c_compile_flags)
    set(extra_swift_compile_flags)

    if (SWIFT_HOST_VARIANT STREQUAL "linux")
      if(NOT "${mod}" MATCHES "-linux-gnu$")
        continue()
      endif()
    elseif (SWIFT_HOST_VARIANT STREQUAL "macosx")
      if(NOT "${mod}" MATCHES "x86_64|arm64|arm64e|armv7|armv7m|armv7em")
        continue()
      endif()

      if(NOT "${mod}" MATCHES "-apple-" OR "${mod}" MATCHES "-none-macho" OR "${arch}" STREQUAL "armv7m" OR "${arch}" STREQUAL "armv7em")
        # Host is macOS with a macOS SDK. To be able to build the C++ Concurrency runtime for non-Darwin targets using the macOS SDK,
        # we need to pass some extra flags and search paths.
        set(extra_c_compile_flags -stdlib=libc++ -isystem${SWIFT_SDK_OSX_PATH}/usr/include/c++/v1 -isystem${SWIFT_SDK_OSX_PATH}/usr/include -D__APPLE__)
      endif()
    endif()

    set(SWIFT_SDK_embedded_THREADING_PACKAGE none)
    set(SWIFT_SDK_embedded_ARCH_${arch}_MODULE "${mod}")
    set(SWIFT_SDK_embedded_ARCH_${mod}_MODULE "${mod}")
    set(SWIFT_SDK_embedded_LIB_SUBDIR "embedded")
    set(SWIFT_SDK_embedded_ARCH_${arch}_TRIPLE "${triple}")
    set(SWIFT_SDK_embedded_ARCH_${mod}_TRIPLE "${triple}")

    # lib/swift/embedded/_Concurrency.swiftmodule
    # lib/swift/embedded/<triple>/libswift_Concurrency.a
    add_swift_target_library_single(
      embedded-concurrency-${mod}
      swift_Concurrency
      STATIC
      IS_STDLIB IS_FRAGILE

      ${SWIFT_RUNTIME_CONCURRENCY_C_SOURCES}
      ${SWIFT_RUNTIME_CONCURRENCY_SWIFT_SOURCES}
      ${SWIFT_RUNTIME_CONCURRENCY_EMBEDDED_SWIFT_SOURCES}

      GYB_SOURCES
        ${SWIFT_CONCURRENCY_GYB_SOURCES}

      SWIFT_COMPILE_FLAGS
        ${extra_swift_compile_flags} -enable-experimental-feature Embedded
        -parse-stdlib -DSWIFT_CONCURRENCY_EMBEDDED
        -Xfrontend -emit-empty-object-file
        ${SWIFT_RUNTIME_CONCURRENCY_SWIFT_FLAGS}
      C_COMPILE_FLAGS
        ${extra_c_compile_flags} ${SWIFT_RUNTIME_CONCURRENCY_C_FLAGS} -DSWIFT_CONCURRENCY_EMBEDDED=1 -DSWIFT_RUNTIME_EMBEDDED=1
        -ffunction-sections -fdata-sections -fno-exceptions -fno-cxx-exceptions -fno-unwind-tables
      MODULE_DIR "${CMAKE_BINARY_DIR}/lib/swift/embedded"
      SDK "embedded"
      ARCHITECTURE "${arch}"
      ARCHITECTURE_SUBDIR_NAME "${mod}"
      DEPENDS embedded-stdlib-${mod}
      INSTALL_IN_COMPONENT stdlib
      )
    swift_install_in_component(
      TARGETS embedded-concurrency-${mod}
      DESTINATION "lib/swift/embedded/${mod}"
      COMPONENT "stdlib"
      )
    swift_install_in_component(
      FILES "${SWIFTLIB_DIR}/embedded/${mod}/libswift_Concurrency.a"
      DESTINATION "lib/swift/embedded/${mod}/"
      COMPONENT "stdlib"
      PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
      )

    if(NOT "${arch}" MATCHES "wasm32")
      set_property(TARGET embedded-concurrency-${mod} PROPERTY OSX_ARCHITECTURES "${arch}")
    endif()
    add_dependencies(embedded-concurrency embedded-concurrency-${mod})

    # lib/swift/embedded/<triple>/libswift_ConcurrencyDefaultExecutor.a
    add_swift_target_library_single(
      embedded-concurrency-default-executor-${mod}
      swift_ConcurrencyDefaultExecutor
      STATIC
      IS_FRAGILE

      CooperativeGlobalExecutor.cpp

      C_COMPILE_FLAGS ${extra_c_compile_flags}
      MODULE_DIR "${CMAKE_BINARY_DIR}/lib/swift/embedded"
      SDK "embedded"
      ARCHITECTURE "${mod}"
      DEPENDS embedded-stdlib-${mod}
      INSTALL_IN_COMPONENT stdlib
      )
    swift_install_in_component(
      TARGETS embedded-concurrency-default-executor-${mod}
      DESTINATION "lib/swift/embedded/${mod}"
      COMPONENT "stdlib"
      )
    swift_install_in_component(
      FILES "${SWIFTLIB_DIR}/embedded/${mod}/libswift_ConcurrencyDefaultExecutor.a"
      DESTINATION "lib/swift/embedded/${mod}/"
      COMPONENT "stdlib"
      PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
      )
    set_property(TARGET embedded-concurrency-default-executor-${mod} PROPERTY OSX_ARCHITECTURES "${arch}")
    add_dependencies(embedded-concurrency embedded-concurrency-default-executor-${mod})
  endforeach()

  # Copy the ExecutorImpl.h header into the local include directory
  # and install it in the compiler toolchain
  add_custom_command(
    OUTPUT "${SWIFT_INCLUDE_DIR}/swift/ExecutorImpl.h"
    DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/ExecutorImpl.h"
    COMMAND "${CMAKE_COMMAND}" "-E" "copy"
            "${CMAKE_CURRENT_SOURCE_DIR}/ExecutorImpl.h"
            "${SWIFT_INCLUDE_DIR}/swift")

  add_custom_target("copy_executor_impl_header"
    DEPENDS "${SWIFT_INCLUDE_DIR}/swift/ExecutorImpl.h"
    COMMENT "Copying executor implementation header to ${SWIFT_INCLUDE_DIR}/swift")

  swift_install_in_component(FILES
    "${CMAKE_CURRENT_SOURCE_DIR}/ExecutorImpl.h"
    DESTINATION "include/swift"
    COMPONENT compiler)

  add_dependencies(embedded-concurrency "copy_executor_impl_header")
endif()
