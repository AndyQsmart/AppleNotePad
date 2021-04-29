qt_compiler_dir="C:/Software/Qt/5.15.2/msvc2019_64" # 结尾不要/
exe_source_dir="./build/release/release/AppleNotePad.exe"
exe_name="AppleNotePad.exe"

# 清空dist文件夹
if [ -d "dist" ]; then
    echo "remove dist folder"
    rm -rf "dist"
fi
echo "create dist folder"
mkdir "dist"
echo "copy exe file"
cp ${exe_source_dir} ./dist/${exe_name}
${qt_compiler_dir}/bin/windeployqt.exe ./dist/${exe_name} --qmldir ${qt_compiler_dir}/qml
echo "copy Qt/labs/platform"
cp -r ${qt_compiler_dir}/qml/Qt/labs/platform ./dist/Qt/labs/platform
echo "copy QtWebEngine"
cp -r ${qt_compiler_dir}/qml/QtWebEngine ./dist/QtWebEngine