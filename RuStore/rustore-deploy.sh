# === Параметры ===

RS_PACKAGE_NAME="com.example.name"

# Параметры черновика
APP_NAME="Название приложения"
APP_TYPE="MAIN"
CATEGORIES="[\"news\",\"education\"]"
AGE_LEGAL="0+"
SHORT_DESCRIPTION="Краткое описание"
FULL_DESCRIPTION="Длинное описание"
WHATS_NEW="Что нового?"
MODER_INFO="Информация для модератора"
PUBLISH_TYPE="MANUAL"
PARTIAL_VALUE="5"
PRIORITY_UPDATE="0"
PRICE_VALUE="999"

# Параметры APK
SERVICES_TYPE="Unknown"
IS_MAIN_APK=true
APK_FILE_PATH="app.apk"
AAB_FILE_PATH="app.aab"

# === Служебные параметры ===

# Служебные параметры логирования
COLOR_RED="[91m"
COLOR_GREEN="[92m"
COLOR_RS_BLUE="[0;34m"
COLOR_CYAN="[96m"
COLOR_RESET="[0m"

ERROR_LOG="${COLOR_RED}Ошибка$COLOR_RESET"
SUCCESS_LOG="${COLOR_GREEN}Успех$COLOR_RESET"
RS_API="${COLOR_RS_BLUE}RuStore API$COLOR_RESET"

RS_API_LOG="[${COLOR_RS_BLUE}RuStore API$COLOR_RESET]"
RS_JWE_SECTION="[${COLOR_CYAN}Получение публичного ключа$COLOR_RESET]"
RS_CVD_SECTION="[${COLOR_CYAN}Создание черновика версии$COLOR_RESET]"
RS_APK_SECTION="[${COLOR_CYAN}Загрузка .apk файла$COLOR_RESET]"
RS_AAB_SECTION="[${COLOR_CYAN}Загрузка .aab файла$COLOR_RESET]"
RS_STM_SECTION="[${COLOR_CYAN}Отправка на модерацию$COLOR_RESET]"


# === Функции ===

# Функция извлекает значение искомого поля
function retrieve_field_from {
	echo $(echo $2 | sed -E 's/.*"'$1'":"?([^,"]*)"?.*/\1/')
}

# Проверка на пустой ответ
function check_if_empty {
	if [ -z "$1" ]
		then
			echo $ERROR_LOG
			echo "Ответ от $RS_API не пришел. Проверьте корректность параметров запроса"
			exit 1
	fi
}

# Поиск поля "message" в ответе с кодом "ERROR"
function find_error_msg {
	if [ "$(retrieve_field_from code "$1")" = "ERROR" ]
		then
			echo "$(retrieve_field_from message "$1")"
	fi
}


# Получение JWE-токена
function get_jwe_token {

	echo -n "$RS_API_LOG $RS_JWE_SECTION Выполнение запроса...  "

	# Форматирование таймстампа
	timestamp=$(date +'%Y-%m-%dT%H:%M:%S.999999999%z')
	timestamp=${timestamp:0:32}:${timestamp:32:33}

	# Хешируеумая строка
	data=$RS_KEY_ID$timestamp

	# Хеш и подпись
	echo "$RS_PRIVATE_KEY" | base64 -d > pkey.p8 | openssl rsa -in pkey.p8 -out rsa.pem > /dev/null 2>&1
	signature=$(echo -ne "$data" | openssl sha512 -sign rsa.pem | base64; rm pkey.p8 rsa.pem)
	signature=$(echo $signature | tr -d '\n' )

	# Запрос токена
	response_json=$(
		curl https://public-api.rustore.ru/public/auth/ \
		--silent \
		--json "{
			\"keyId\":\"${RS_KEY_ID}\",
			\"timestamp\":\"${timestamp}\",
			\"signature\":\"${signature}\"
		}"
	)

	# Обработка результата
	check_if_empty "${response_json}"

	if [ "$(retrieve_field_from code "${response_json}")" = "OK" ]
		then
			JWE_TOKEN=$(retrieve_field_from jwe "${response_json}")
			echo $SUCCESS_LOG
		else
			echo $ERROR_LOG
			find_error_msg "${response_json}"
			exit 1
	fi

}

# Создание черновика версии
function create_version_draft {

	echo -n "$RS_API_LOG $RS_CVD_SECTION Выполнение запроса...  "

	# Запрос создания черновика
	create_draft_json=$(
		curl \
		--silent \
		--location \
		--request POST "https://public-api.rustore.ru/public/v1/application/$RS_PACKAGE_NAME/version" \
		--header 'Content-Type: application/json' \
		--header "Public-Token: $JWE_TOKEN" \
		--json "{
			\"appName\":\"$APP_NAME\",
			\"appType\":\"$APP_TYPE\",
			\"categories\": $CATEGORIES,
			\"ageLegal\":\"$AGE_LEGAL\",
			\"shortDescription\":\"$SHORT_DESCRIPTION\",
			\"fullDescription\":\"$FULL_DESCRIPTION\",
			\"whatsNew\":\"$WHATS_NEW\",
			\"moderInfo\":\"$MODER_INFO\",
			\"publishType\":\"$PUBLISH_TYPE\",
			\"partialValue\":\"$PARTIAL_VALUE\"

		}"
	)

	# Обработка результата
	check_if_empty "${create_draft_json}"

	if [ "$(retrieve_field_from code "${create_draft_json}")" = "OK" ]
		then
			VERSION_ID=$(retrieve_field_from body "${create_draft_json}")
			echo $SUCCESS_LOG
		else
			echo $ERROR_LOG
			find_error_msg "${create_draft_json}"
			exit 1
	fi
}

# Загрузка APK
function upload_apk {
	echo -e "$RS_API_LOG $RS_APK_SECTION Выполнение запроса...  "

	# Запрос загрузки
	upload_apk_json=$(
		curl \
		--silent \
		--request POST "https://public-api.rustore.ru/public/v1/application/$RS_PACKAGE_NAME/version/$VERSION_ID/apk?servicesType=$SERVICES_TYPE&isMainApk=$IS_MAIN_APK" \
		--header "Public-Token: $JWE_TOKEN" \
		--form "file=@\"$APK_FILE_PATH\""
	)

	# Обработка результата
	check_if_empty "${upload_apk_json}"

	if [ "$(retrieve_field_from code "${upload_apk_json}")" = "OK" ]
		then
			echo $SUCCESS_LOG
		else
			echo $ERROR_LOG
			find_error_msg "${upload_apk_json}"
			exit 1
	fi
}

# Загрузка AAB
function upload_aab {
	echo -n "$RS_API_LOG $RS_AAB_SECTION Выполнение запроса...  "

	# Запрос создания черновика
	upload_aab_json=$(
		curl \
		--silent \
		--location \
		--request POST "https://public-api.rustore.ru/public/v1/application/$RS_PACKAGE_NAME/version/$VERSION_ID/aab" \
		--header "Public-Token: $JWE_TOKEN" \
		--form "file=@\"$AAB_FILE_PATH\""
	)

	# Обработка результата
	check_if_empty "${upload_aab_json}"

	if [ "$(retrieve_field_from code "${upload_aab_json}")" = "OK" ]
		then
			echo $SUCCESS_LOG
		else
			echo $ERROR_LOG
			find_error_msg "${upload_aab_json}"
			exit 1
	fi
}

# Отправка черновика на модерацию
function send_to_moderation {

	echo -n "$RS_API_LOG $RS_STM_SECTION Выполнение запроса...  "

	# Запрос
	send_to_moderation_json=$(
		curl \
		--silent \
		--location \
		--request POST "https://public-api.rustore.ru/public/v1/application/$RS_PACKAGE_NAME/version/$VERSION_ID/commit?priorityUpdate=$PRIORITY_UPDATE" \
		--header "Public-Token: $JWE_TOKEN"
	)

	# Обработка результата
	check_if_empty "${send_to_moderation_json}"

	if [ "$(retrieve_field_from code "${send_to_moderation_json}")" = "OK" ]
		then
			echo $SUCCESS_LOG
		else
			echo $ERROR_LOG
			find_error_msg "${send_to_moderation_json}"
			exit 1
	fi
}

# === Сценарий ===
function main {
  get_jwe_token
  create_version_draft
  upload_apk
  # upload_aab
  send_to_moderation
}

main
