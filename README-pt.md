# BluePic

[![Build Status - Master](https://travis-ci.org/IBM/BluePic.svg?branch=master)](https://travis-ci.org/IBM/BluePic)
![Bluemix Deployments](https://deployment-tracker.mybluemix.net/stats/c45eeb765e77bf2bffd747e8d910e37d/badge.svg)

O BluePic é um aplicativo de amostra para compartilhamento de fotos e imagens que permite tirar fotos e compartilhá-las com outros usuários. Esse aplicativo de amostra demonstra como utilizar, em um aplicativo móvel para iOS 10, um aplicativo do servidor baseado em Kitura escrito no Swift.

O BluePic aproveita o Swift em uma configuração do cliente típica para iOS, mas também no lado do servidor, usando a nova estrutura da web do Swift e um servidor HTTP (Kitura). Uma característica interessante do BluePic é a forma como ele trata as fotos no servidor. Quando uma imagem é publicada, seus dados são registrados no Cloudant e o binário da imagem é armazenado no Object Storage. A partir dali, uma sequência do [OpenWhisk](http://www.ibm.com/cloud-computing/bluemix/openwhisk/) é chamada. Ela provoca o cálculo de dados meteorológicos, como temperatura e condição atual (por exemplo, ensolarado, nublado etc.), com base no local no qual foi feito o upload da imagem. O Watson Visual Recognition também é usado na sequência do OpenWhisk para analisar a imagem e extrair tags de texto de acordo com o conteúdo da imagem. Por fim, uma notificação push é enviada ao usuário, informando que a imagem foi processada e passou a incluir dados meteorológicos e de tag.

## Versão do Swift
Os componentes de backend (ou seja, servidor baseado em Kitura e ações do OpenWhisk) e o componente de iOS do aplicativo BluePic funcionam com versões específicas dos binários do Swift. Consulte a tabela a seguir:

| Componente | Versão do Swift |
| --- | --- |
| Servidor baseado em Kitura | `3.1.1` |
| Ações do OpenWhisk | `3.0` |
| Aplicativo de iOS | Xcode 8.3 padrão (`Swift 3.1`)

Para fazer download dos instantâneos de desenvolvimento dos binários do Swift, siga este [link](https://swift.org/download/). Não há garantia de compatibilidade com outras versões do Swift.

Opcionalmente, se quiser executar o servidor baseado em Kitura do BluePic usando Xcode, utilize o Xcode 8 e configure-o para usar a cadeia de ferramentas padrão. Para ver detalhes a respeito de como configurar o Xcode, consulte [Desenvolvendo seu aplicativo Kitura no XCode](https://github.com/IBM-Swift/Kitura/wiki/Building-your-Kitura-application-on-XCode/d43b796976bfb533d3d209948de17716fce859b0). Não há garantia de que outras versões do Xcode funcionarão com o código de backend.

Como mostrado na tabela acima, o componente de iOS do aplicativo BluePic usa a cadeia de ferramentas padrão (Swift 3.1) predefinida com o Xcode 8.3. No momento, não há garantia de que outras versões do Xcode vão funcionar, mas você poderá visualizar [liberações](https://github.com/IBM/BluePic/releases) anteriores em busca de possível compatibilidade com versões mais antigas do Xcode (ou seja, Xcode 7.3.1). Poderão ocorrer erros e/ou comportamento inesperado ao tentar usar outras versões do Xcode ou do Swift.

## Introdução
Existem *duas maneiras* de compilar e fornecer o BluePic no Bluemix. O método 1 usa o aplicativo [IBM Cloud Tools for Swift](https://ibm-cloud-tools.mybluemix.net/). O uso do IBM Cloud Tools for Swift é o caminho mais fácil e mais rápido para fazer o BluePic funcionar. O método 2 é manual, não utiliza essa ferramenta e, portanto, demora mais; porém, é possível entender exatamente as etapas que estão ocorrendo nos bastidores. Independentemente do caminho escolhido, algumas etapas opcionais podem ser concluídas para uma funcionalidade adicional.

## Método 1: IBM Cloud Tools for Swift
Após instalar o aplicativo IBM Cloud Tools for Swift para Mac, é possível abri-lo para começar. Na tela para criação de um novo projeto, você encontrará a opção de criar um Projeto do BluePic. Selecione essa opção e nomeie seu projeto/tempo de execução. Isso dará início a um processo que fará o seguinte automaticamente:

- Instala curl no sistema local (exige o Homebrew).
- Clona o repositório do BluePic no seu Mac.
- Cria o tempo de execução do Bluemix (ou seja, servidor baseado em Kitura) e fornece os serviços do Bluemix que o BluePic pode utilizar.
- Preenche os serviços do Cloudant e do Object Storage com dados de demonstração.
- Atualiza o arquivo `configuration.json` com todas as credenciais de serviço exigidas pelo servidor baseado em Kitura.
- Atualiza o arquivo `cloud.plist` [no projeto do Xcode] para o aplicativo de iOS se conectar com o servidor remoto baseado em Kitura em execução no Bluemix.

Depois que o IBM Cloud Tools for Swift concluir as etapas acima, será possível [executar o aplicativo](#running-the-ios-app). Se desejar, você também poderá configurar os serviços do Bluemix que foram fornecidos para ativar [recursos opcionais](#optional-features-to-configure) no BluePic (tais como autenticação pelo Facebook e notificações push).

## Método 2: Configuração e implementação manuais
Em vez de usar o IBM Cloud Tools for Swift, que proporciona uma experiência contínua de compilação e fornecimento, você poderá seguir as etapas descritas nesta seção se quiser saber como as coisas funcionam!

### 1. Instalar dependências do sistema
As dependências de nível do sistema a seguir devem ser instaladas no MacOS usando o [Homebrew](http://brew.sh/):

```bash
brew install curl
```

Se estiver usando o Linux como plataforma de desenvolvimento, você poderá encontrar informações completas sobre como configurar seu ambiente para desenvolver aplicativos baseados em Kitura em [Introdução ao Kitura](https://github.com/IBM-Swift/Kitura).

### 2. Clonar o repositório Git do BluePic
Execute o comando a seguir para clonar o repositório Git:

```bash
git clone https://github.com/IBM/BluePic.git
```

Se desejar, você poderá dispor de alguns minutos para conhecer a estrutura de pastas do repositório, descrita na página [Sobre](Docs/About.md).

### 3. Criar o aplicativo BluePic no Bluemix
Ao clicar no botão abaixo, o aplicativo BluePic é implementado no Bluemix. O arquivo [`manifest.yml`](manifest.yml) [incluso no repositório] passa por análise sintática para obter o nome do aplicativo e determinar os serviços do Cloud Foundry que devem ser instanciados. Para ver mais detalhes sobre a estrutura do arquivo `manifest.yml`, consulte a [documentação do Cloud Foundry](https://docs.cloudfoundry.org/devguide/deploy-apps/manifest.html#minimal-manifest). Após clicar no botão abaixo, você poderá nomear seu aplicativo. Lembre-se de que o nome do aplicativo do Bluemix precisa corresponder ao valor do nome no `manifest.yml`. Portanto, talvez seja necessário alterar o valor do nome no `manifest.yml` se houver um conflito de nomenclatura na conta do Bluemix.

[![Deploy to Bluemix](https://deployment-tracker.mybluemix.net/stats/c45eeb765e77bf2bffd747e8d910e37d/button.svg)](https://bluemix.net/deploy?repository=https://github.com/IBM/BluePic.git&cm_mmc=github-code-_-native-_-bluepic-_-deploy2bluemix)

Quando a implementação no Bluemix for concluída, você deverá acessar a rota atribuída ao aplicativo usando o navegador da web que preferir. A página de boas-vindas do Kitura deve ser exibida!

Observe que o [buildpack do Bluemix para Swift](https://github.com/IBM-Swift/swift-buildpack) é utilizado para a implementação do BluePic no Bluemix. No momento, esse buildpack é instalado nas regiões do Bluemix a seguir: Sul dos Estados Unidos, Reino Unido e Sydney.

### 4. Preencher o banco de dados do Cloudant
Para preencher a instância de banco de dados do Cloudant com dados de amostra, é necessário obter os valores de credencial a seguir:

- `username` - O nome do usuário da sua instância do Cloudant.
- `password` - A senha da sua instância do Cloudant.
- `projectId` - O ID do projeto da sua instância do Object Storage.

Para obter as credenciais acima, acesse a página do aplicativo no Bluemix e clique na torção `Show Credentials`, disponível nas instâncias de serviço do Cloudant e do Object Storage. Quando tiver essas credenciais, navegue até o diretório `Cloud-Scripts/cloudantNoSQLDB/`, no repositório do BluePic, e execute o script `populator.sh` como mostrado abaixo:

```bash
./populator.sh --username=<cloudant username> --password=<cloudant password> --projectId=<object storage projectId>

```

### 5. Preencher o Object Storage
Para preencher a instância do Object Storage com dados de amostra, é necessário obter os valores de credencial a seguir (a região é opcional):

- `userID` - O ID do usuário da sua instância do Object Storage.
- `password` - A senha da sua instância do Object Storage.
- `projectId` - O ID do projeto da sua instância do Object Storage.
- `region` - Como opção, é possível definir a região em que o Object Storage deverá salvar seus dados: `london` para Londres ou `dallas` para Dallas. Se a região não for definida, o padrão é `dallas`.

Para obter as credenciais acima, acesse a página do aplicativo no Bluemix e clique na torção `Show Credentials`, disponível na instância do Object Storage. Quando tiver essas credenciais, navegue até o diretório `./Cloud-Scripts/Object-Storage/`, no repositório do BluePic, e execute o script `populator.sh` como mostrado abaixo:

```bash
./populator.sh --userId=<object storage userId> --password=<object storage password> --projectId=<object storage projectId> --region=<object storage region>
```

### 6. Atualizar o arquivo `BluePic-Server/config/configuration.json`
Agora, é necessário atualizar as credenciais para cada serviço listado no arquivo `BluePic-Server/config/configuration.json`. Assim, o servidor baseado em Kitura pode ser executado localmente para fins de desenvolvimento e teste. Você encontrará itens temporários no arquivo `configuration.json` (por exemplo, `<username>`, `<projectId>`) para cada valor de credencial que deve ser fornecido.

Lembre-se: para obter as credenciais para cada serviço listado no arquivo `configuration.json`, você pode acessar a página do aplicativo no Bluemix e clicar na torção `Show Credentials`, disponível em cada instância de serviço associada ao aplicativo BluePic.

Para ver o conteúdo do arquivo `configuration.json`, clique [aqui](BluePic-Server/config/configuration.json).

### 7. Atualizar a configuração para o aplicativo de iOS
Acesse o diretório `BluePic-iOS` e abra a área de trabalho do BluePic com o Xcode usando `open BluePic.xcworkspace`. Agora, vamos atualizar o `cloud.plist` no projeto do Xcode (é possível encontrar esse arquivo na pasta `Configuration` do projeto do Xcode).

1. Você deverá definir o valor `isLocal` como `YES` se quiser usar um servidor de execução local; se o valor for definido como `NO`, você acessará a instância do servidor em execução no Bluemix.

1. Para obter o valor `appRouteRemote`, acesse a página do seu aplicativo no Bluemix. Lá, haverá um botão `View App` perto do canto superior direito. Ao clicar nele, seu aplicativo será aberto em uma nova guia. A URL dessa página é a `rota` que leva até a chave `appRouteRemote` na plist. Não se esqueça de incluir o protocolo `http://` na `appRouteRemote` e de excluir uma barra invertida no final da URL.

1. Por fim, precisamos obter o valor para `cloudAppRegion`, que, no momento, pode ser uma dentre três opções:

REGION US SOUTH | REGION UK | REGION SYDNEY
--- | --- | ---
`.ng.bluemix.net` | `.eu-gb.bluemix.net` | `.au-syd.bluemix.net`

Existem várias maneiras de localizar sua região. Por exemplo, basta olhar para a URL usada para acessar a página do seu aplicativo (ou o painel do Bluemix). Outra maneira é examinar o arquivo `configuration.json` que foi modificado antes. Se você olhar as credenciais no serviço `AppID`, verá um valor chamado `oauthServerUrl`, que deve conter uma das regiões mencionadas acima. Depois de inserir o valor `cloudAppRegion` na `cloud.plist`, seu aplicativo deve ser configurado.

## Recursos opcionais a serem configurados
Esta seção descreve as etapas que precisam ser executadas para utilizar a autenticação por Facebook com App ID, Notificações Push e OpenWhisk.

*No momento, os terminais de API no BluePic-Server não estão protegidos por causa das limitações de dependência, mas serão em breve, pois essa funcionalidade está disponível com os SDKs do Kitura e de App ID*

### 1. Criar uma instância do aplicativo no Facebook
Para o aplicativo ser autenticado com o Facebook, deve-se criar uma instância do aplicativo no website do Facebook.

1. Acesse o diretório `BluePic-iOS` e abra a área de trabalho do BluePic com o Xcode usando `open BluePic.xcworkspace`.

1. Escolha um identificador de pacote configurável para seu aplicativo e atualize o projeto do Xcode de acordo: Selecione o ícone da pasta do navegador do projeto, localizado no canto superior esquerdo do Xcode; depois, selecione o projeto do BluePic na parte superior da estrutura de arquivos e, a seguir, selecione o destino do BluePic. Na seção de identidade, você deve ver um campo de texto para o identificador do pacote configurável. Atualize esse campo com um identificador do pacote configurável escolhido por você (ou seja, com.bluepic).

1. Acesse a página [Iniciação Rápida para iOS do Facebook](https://developers.facebook.com/quickstarts/?platform=ios) para criar uma instância do aplicativo. Digite `BluePic` como o nome do novo aplicativo do Facebook e clique no botão `Create New Facebook App ID`. Escolha qualquer categoria para o aplicativo e clique no botão `Create App ID`.

1. Na tela a seguir, observe que **não** é necessário fazer download do SDK do Facebook. O SDK do App ID (já incluso no projeto de iOS) tem todos os códigos necessários para dar suporte à autenticação pelo Facebook. Na seção `Configure your info.plist`, copie o valor `FacebookAppID` e insira nos campos `URL Schemes` e `FacebookAppID` no `info.plist` para que sua plist fique parecida com a imagem abaixo. O arquivo `info.plist` está disponível na pasta `Configuration` do projeto do Xcode.
<p align="center"><img src="Imgs/infoplist.png"  alt="Drawing" height=150 border=0 /></p>

1. Em seguida, role até a parte inferior da página de iniciação rápida do Facebook, na qual diz `Supply us with your Bundle Identifier`, e insira o identificador do pacote configurável do aplicativo que foi escolhido na etapa 2.

1. Isso é para configurar a instância do aplicativo do BluePic no website Facebook Developer. Na próxima seção, vincularemos essa instância de aplicativo do Facebook com seu serviço de App ID do Bluemix.

### 2. Configurar o App ID do Bluemix
1. Acesse a página do aplicativo no Bluemix e abra a instância de serviço do `App ID`:
<p align="center"><img src="Imgs/app-id-service.png"  alt="Drawing" height=125 border=0 /></p>

1. Na página seguinte, clique no botão `Identity Providers`, na lateral. Você deverá ver algo parecido com isto:
<p align="center"><img src="Imgs/configure-facebook.png"  alt="Drawing" height=125 border=0 /></p>

1. Coloque o interruptor de duas posições em On, para o Facebook, e clique no botão Edit. Aqui, insira o App ID do Facebook e o segredo da página do aplicativo do Facebook (consulte a seção [Criar uma instância do aplicativo no Facebook](#1-create-an-application-instance-on-facebook) para ver os detalhes).
<p align="center"><img src="Imgs/facebook-appid-setup.png"  alt="Drawing" height=250 border=0 /></p>

1. Nesta página, você também verá “Redirect URL for Facebook for Developers”; copie, porque precisaremos em breve. Na página do aplicativo Facebook Developer, navegue até o produto de login do Facebook. Essa URL é `https://developers.facebook.com/apps/<facebookAppId>/fb-login/`. Aqui, cole esse link no campo “Valid OAuth redirect URIs” e clique em Save changes. De volta ao Bluemix, é possível clicar também no botão Save.

1. Outra coisa que precisa ser feita para o App ID funcionar corretamente é incluir o `tenantId` para o App ID no `cloud.plist` para o BluePic-iOS. O `tenantId` é obtido ao visualizar as credenciais para o serviço de App ID no Bluemix; todos os seus serviços devem estar na guia `Connections` do seu aplicativo no Bluemix. Lá, clique no botão “View Credentials” ou “Show Credentials” para o serviço de App ID. Deve ser exibido o pop-up `tenantId `, entre outros valores. Agora, basta inserir esse valor no `cloud.plist` correspondente à chave `appIdTenantId`.

1. A autenticação por Facebook com o App ID do Bluemix foi completamente configurada!

### 3. Configurar o serviço Bluemix Push
Para realizar o push dos recursos de notificação push no Bluemix, é necessário configurar um provedor de notificação. Para o BluePic, você deve configurar credenciais para o Apple Push Notification Service (APNS). Como parte dessa etapa da configuração, você deverá usar o **identificador do pacote configurável** que escolheu na seção [Criar uma instância do aplicativo no Facebook](#1-create-an-application-instance-on-facebook).

Felizmente, o Bluemix tem [instruções](https://console.ng.bluemix.net/docs/services/mobilepush/t_push_provider_ios.html) que explicam o processo de configurar o APNS com o serviço Bluemix Push. Observe que seria necessário fazer upload de um certificado `.p12` para o Bluemix e inserir a senha para ele, como descrito nas instruções do Bluemix.

Além disso, o `appGuid` para o serviço de push age de forma independente do aplicativo BluePic; portanto, precisaremos incluir esse valor no `cloud.plist`. Também precisamos do valor `clientSecret` para o serviço de push. O `appGuid` e o `clientSecret` são obtidos ao visualizar as credenciais para o serviço de push no Bluemix; todos os seus serviços devem estar na guia `Connections` do aplicativo. Lá, clique no botão `View Credentials` ou `Show Credentials` para o serviço de Notificações Push. Deve ser exibido o pop-up `appGuid`, entre outros valores. Agora, basta inserir esse valor no `cloud.plist` correspondente à chave `pushAppGUID`. Em seguida, você deve ver o valor `clientSecret`, que pode ser utilizado para preencher o campo `pushClientSecret` no `cloud.plist`. Isso deve garantir que seu dispositivo seja registrado de forma adequada com o serviço de push.

Por fim, lembre-se de que as notificações push serão exibidas apenas em um dispositivo físico com iOS. Para assegurar que seu aplicativo possa ser executado em um dispositivo e receber notificações push, lembre-se de seguir as [instruções do Bluemix](https://console.ng.bluemix.net/docs/services/mobilepush/t_push_provider_ios.html) acima. Nesse ponto, abra o `BluePic.xcworkspace` no Xcode e navegue até a guia `Capabilities` para o destino do aplicativo BluePic. Aqui, acione o interruptor para notificações push, deste modo:

<p align="center"><img src="Imgs/enablePush.png"  alt="Drawing" height=145 border=0 /></p>

Agora, verifique se seu aplicativo está usando o perfil de fornecimento habilitado para push que foi criado antes, nas instruções do Bluemix. Neste ponto, é possível executar o aplicativo no seu dispositivo e receber notificações push.

### 4. Configurar o OpenWhisk
O BluePic utiliza ações do OpenWhisk escritas no Swift para acessar as APIs do Watson Visual Recognition e Weather. Para obter instruções a respeito de como configurar o OpenWhisk, consulte a [página](Docs/OpenWhisk.md) a seguir. Lá, você encontrará detalhes sobre configuração e chamada de comandos do OpenWhisk.

### 5. Reimplementar o aplicativo BluePic no Bluemix
#### Usando o IBM Cloud Tools for Swift
Depois de configurar os recursos opcionais, você deve reimplementar o aplicativo BluePic no Bluemix. Caso tenha usado o IBM Cloud Tools for Swift para implementar inicialmente o aplicativo BluePic no Bluemix, você também poderá usar essa ferramenta para reimplementar o aplicativo. Na página do projeto no IBM Cloud Tools for Swift, localize uma entrada para o tempo de execução do aplicativo BluePic. Nessa entrada, você encontrará opções para implementar o tempo de execução no Bluemix, conforme mostrado aqui:

<p align="center"><img src="Imgs/cloud-tools-deploy.png"  alt="Deploy to server" height=250 border=0 /></p>

#### Usando a interface de linha de comando do Bluemix
Depois de configurar os recursos opcionais, você deve reimplementar o aplicativo BluePic no Bluemix. É possível usar a CLI do Bluemix para fazer isso. Faça o download [aqui](http://clis.ng.bluemix.net/ui/home.html). Após efetuar login no Bluemix usando a linha de comando, você poderá executar `bx app push` na pasta raiz desse repositório, no seu sistema de arquivos local. Será realizado o push do código e da configuração do aplicativo para o Bluemix.

## Executando o aplicativo de iOS
Caso o projeto de iOS ainda não esteja aberto, acesse o diretório `BluePic-iOS` e abra a área de trabalho do BluePic usando `open BluePic.xcworkspace`.

Agora, é possível desenvolver e executar o aplicativo de iOS no simulador usando os recursos do Xcode com os quais está acostumado!

### Executando o aplicativo de iOS em um dispositivo físico

Os desenvolvedores da IBM devem consultar nossa [Wiki](https://github.com/IBM/BluePic/wiki/Code-Signing-Configuration-for-Internal-Developers) para ver detalhes sobre as etapas que devem ser seguidas.

O método mais fácil para executar o aplicativo de iOS em um dispositivo físico é alterar o ID do pacote configurável do BluePic para um valor exclusivo (caso ainda não tenha feito isso). Em seguida, marque a caixa `Automatically manage signing`, localizada na guia `General`, para o destino do aplicativo BluePic (no Xcode). Depois de marcar essa caixa, você precisará assegurar que a equipe da sua conta pessoal do Apple Developer será selecionada na lista suspensa. Supondo que você tem a função de `Agent` ou `Admin` na equipe do Apple Developer Program, será criado um perfil de fornecimento para o aplicativo BluePic ou será usado um perfil curinga (se houver), permitindo a execução em um dispositivo.

Como alternativa, é possível configurar manualmente a assinatura do código do aplicativo usando um App ID curinga para executar o aplicativo no seu dispositivo. Caso já tenha sido criado, basta selecioná-lo na lista suspensa do perfil de fornecimento na seção `Signing (Debug)`. Caso contrário, crie um por meio do Apple Developer Portal. Este [link](https://developer.apple.com/library/content/qa/qa1713/_index.html) deve ser útil para fornecer mais informações sobre IDs do Aplicativo curingas.

## Executando o servidor baseado em Kitura localmente
Para desenvolver o BluePic-Server, acesse o diretório `BluePic-Server` do repositório clonado e execute `swift build`. Para iniciar o servidor baseado em Kitura para o aplicativo BluePic no seu sistema local, acesse o diretório `BluePic-Server` do repositório clonado e execute `.build/debug/BluePicServer`. Você também deve atualizar o arquivo `cloud.plist` no projeto do Xcode para o aplicativo de iOS se conectar com o servidor local. Consulte a seção [Atualizar a configuração para o aplicativo de iOS](#7-update-configuration-for-ios-app) para saber mais.

## Usando o BluePic
O BluePic foi criado com muitos recursos úteis. Para obter mais informações e detalhes a respeito do uso do aplicativo de iOS, confira nosso passo a passo na página [Usando o BluePic](Docs/Usage.md).

## Sobre o BluePic
Para saber mais a respeito da estrutura de pastas do BluePic, sua arquitetura e os pacotes do Swift dos quais ele depende, consulte a página [Sobre](Docs/About.md).

#### Notificando problemas com relação ao IBM Cloud Tools for Swift
É possível usar o website [dW Answers](https://developer.ibm.com/answers/topics/cloud-tools-for-swift.html) para fazer uma pergunta e/ou notificar algum problema encontrado durante o uso do IBM Cloud Tools for Swift. Não se esqueça de usar a tag `cloud-tools-for-swift` para as perguntas publicadas no dW Answers.

## Aviso de Privacidade
O aplicativo BluePic-Server inclui um código para acompanhar implementações no [IBM Bluemix](https://www.bluemix.net/) e em outras plataformas do Cloud Foundry. As informações a seguir são enviadas para um serviço de [Rastreador de Implementação](https://github.com/IBM-Bluemix/cf-deployment-tracker-service) em cada implementação:

* Versão do código do projeto do Swift (se for fornecida)
* URL do repositório do projeto do Swift
* Nome do Aplicativo (`application_name`)
* ID do Espaço (`space_id`)
* Versão do Aplicativo (`application_version`)
* URIs do Aplicativo (`application_uris`)
* Etiquetas de serviços de limite
* Número de instâncias para cada serviço de limite e informações do plano associado

Esses dados são coletados a partir dos parâmetros do `CloudFoundryDeploymentTracker` e das variáveis de ambiente `VCAP_APPLICATION` e `VCAP_SERVICES` no IBM Bluemix e em outras plataformas do Cloud Foundry. Esses dados são utilizados pela IBM para o acompanhamento de métricas a respeito de implementações dos mesmos aplicativos no IBM Bluemix. O objetivo é determinar a utilidade dos nossos exemplos para podermos melhorar continuamente o conteúdo que oferecemos a você. Somente implementações de aplicativos de amostra que incluem código para fazer ping do serviço de Rastreador da Implementação serão acompanhadas.

## Desativando o acompanhamento da implementação
Para desativar o acompanhamento de implementação, basta remover a linha a seguir do `main swift`:

    CloudFoundryDeploymentTracker(repositoryURL: "https://github.com/IBM-Swift/Kitura-Starter-Bluemix.git", codeVersion: nil).track()

## Licença
Este aplicativo é licenciado conforme o Apache 2.0. O texto completo da licença está disponível em [LICENÇA](LICENÇA).

Para obter uma lista das imagens de demonstração usadas, visualize o arquivo [Fontes das Imagens](Docs/ImageSources.md).
