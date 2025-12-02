#!/bin/bash
rm -rf ts-proto;
mkdir ts-proto;

protoc --plugin=$(npm root)/.bin/protoc-gen-ts_proto \
 --proto_path=$(pwd)/proto \
 --ts_proto_out=$(pwd)/ts-proto \
 --ts_proto_opt=nestJs=true \
 --ts_proto_opt=esModuleInterop=true \
 --ts_proto_opt=outputEncodeMethods=false \
 --ts_proto_opt=outputJsonMethods=false \
 --ts_proto_opt=outputClientImpl=false \
 --ts_proto_opt=exportCommonSymbols=false \
 $(pwd)/proto/*.proto

for proto_file in ./proto/*.proto; do
    # Отримання імені файлу без каталогу
    filename=$(basename -- "$proto_file")

    # Видалення розширення файлу для отримання основної частини імені
    filename_no_ext="${filename%.*}"

    # Конвертуємо ім'я файлу у верхній регістр для використання у змінній
    filename_upper=$(echo "$filename_no_ext" | tr '[:lower:]' '[:upper:]')

    # Витягнення значення package з файлу .proto за допомогою sed
    package_name=$(awk -F '[ ;]' '{for(i=1;i<=NF;i++) if($i=="package") print $(i+1)}' "$proto_file")

    # Більше відлагоджувальної інформації
    echo "Extracted package name: '$package_name' from file '$proto_file'"

    # Перевірка, чи вдалося знайти ім'я пакету
    if [ -n "$package_name" ]; then
        # Файл призначення у папці ts-proto
        ts_file="./ts-proto/$filename_no_ext.ts"

        echo "export const ${filename_upper}_PACKAGE_NAME = \"$package_name\";" >> "$ts_file"
        echo "export const ${filename_upper}_PACKAGE_PROTO_FILENAME = \"$filename\";" >> "$ts_file"
    else
        echo "Error: Package name not found in $proto_file" >&2
        exit 1
    fi
done

# Генерація індексного файлу
for ts_file in ./ts-proto/*.ts; do
    filename=$(basename -- "$ts_file")
    filename_no_ext="${filename%.*}"
    echo "export * from './ts-proto/$filename_no_ext';" >> ./index.ts
done

./node_modules/.bin/tsc
