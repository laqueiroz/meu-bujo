// Modelo do arquivo de configuração do Google.
// Copie este arquivo para lib/config_google.dart e cole o ID do cliente "Aplicativo da Web"
// criado no Google Cloud (veja o README). O config_google.dart de verdade fica fora do git.
// A chave secreta do cliente NÃO vai em nenhum dos dois.
const googleWebClientId = 'COLE_AQUI_O_ID_DO_CLIENTE_WEB.apps.googleusercontent.com';

bool get googleConfigurado => !googleWebClientId.startsWith('COLE_AQUI');
