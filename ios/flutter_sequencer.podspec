#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_sequencer.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_sequencer'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }

  # ✅ Avoid source duplication
  s.source_files = 'Classes/**/*.{h,m,mm,cpp,swift}', 'prepare.sh'

  # ✅ No public headers — avoids Xcode multiple definition error
  s.public_header_files = []

  # ✅ MERGED xcconfig block
  s.xcconfig = {
    'USER_HEADER_SEARCH_PATHS' => '"${PROJECT_DIR}/.."/Classes/CallbackManager/*,"${PROJECT_DIR}/.."/Classes/Scheduler/*,"${PROJECT_DIR}/.."/Classes/AudioUnit/*,"${PROJECT_DIR}/.."/Classes/AudioUnit/Sfizz/*,"${PROJECT_DIR}/.."/Classes/AudioUnit/Sfizz/SfizzDSPKernelAdapter.h',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++2a',
    'CLANG_CXX_LIBRARY' => 'libc++'
  }

  s.dependency 'Flutter'
  s.static_framework = true
  s.platform = :ios, '13.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'ENABLE_TESTABILITY' => 'YES',
    'STRIP_STYLE' => 'non-global',
    'HEADER_SEARCH_PATHS' => '$(PODS_TARGET_SRCROOT)/third_party/sfizz/src $(PODS_TARGET_SRCROOT)/Classes/AudioUnit $(PODS_TARGET_SRCROOT)/Classes',
    # 確保 FFI 符號在 Archive 構建時不被剝離
    # 導出所有從 Dart 端動態查找的 C 函數符號
    'OTHER_LDFLAGS' => '-Wl,-exported_symbol,_RegisterDart_PostCObject -Wl,-exported_symbol,_setup_engine -Wl,-exported_symbol,_destroy_engine -Wl,-exported_symbol,_add_track_sf2 -Wl,-exported_symbol,_add_track_sfz -Wl,-exported_symbol,_add_track_sfz_string -Wl,-exported_symbol,_remove_track -Wl,-exported_symbol,_stop_all_notes -Wl,-exported_symbol,_reset_track -Wl,-exported_symbol,_get_position -Wl,-exported_symbol,_get_track_volume -Wl,-exported_symbol,_get_last_render_time_us -Wl,-exported_symbol,_get_buffer_available_count -Wl,-exported_symbol,_handle_events_now -Wl,-exported_symbol,_schedule_events -Wl,-exported_symbol,_clear_events -Wl,-exported_symbol,_engine_play -Wl,-exported_symbol,_engine_pause'
  }

  s.user_target_xcconfig = {
    # 允許 arm64 模擬器以支持 iPhone 16e 等新設備
  }

  s.swift_version = '5.0'
  s.library = 'c++'
  s.prepare_command = './prepare.sh'
  s.vendored_libraries = 'third_party/sfizz/build/libsfizz_fat.a'
  
  # Add a script phase to dynamically select the correct library based on build target
  s.script_phases = [
    {
      :name => 'Select Correct Library',
      :script => 'LIB_DIR="${PODS_TARGET_SRCROOT}/third_party/sfizz/build"; FAT_LIB="${LIB_DIR}/libsfizz_fat.a"; DEVICE_LIB="${LIB_DIR}/libsfizz_device.a"; SIMULATOR_LIB="${LIB_DIR}/libsfizz_simulator.a"; if [ "${PLATFORM_NAME}" = "iphonesimulator" ]; then if [ -f "${SIMULATOR_LIB}" ] && [ -f "${FAT_LIB}" ]; then cp "${SIMULATOR_LIB}" "${FAT_LIB}"; echo "Selected simulator library for ${PLATFORM_NAME}"; fi; else if [ -f "${DEVICE_LIB}" ] && [ -f "${FAT_LIB}" ]; then cp "${DEVICE_LIB}" "${FAT_LIB}"; echo "Selected device library for ${PLATFORM_NAME}"; fi; fi',
      :execution_position => :before_compile
    }
  ]

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'flutter_sequencer_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
