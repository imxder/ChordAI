# Política de privacidade

Última atualização: 20/11/2026

Eu sou o Alexandre Salgado e fiz o ChordAI como meu TCC de Engenharia de Software na Católica SC. Aqui eu explico, seguindo a LGPD (Lei 13.709/2018), quais dados o app usa, pra quê, onde eles ficam e o que você pode fazer com eles.

Resumindo: o app não tem conta, não tem anúncio, não tem analytics e não manda nada pra mim. Tudo que ele guarda fica no seu aparelho.

## Quem cuida dos dados

O responsável (controlador, na LGPD) sou eu, Alexandre Salgado, pessoa física. Não existe empresa por trás do app.

## O que o app guarda no seu aparelho

O app guarda algumas informações na memória do próprio aparelho, pra lembrar de você quando abrir de novo. Nada disso é enviado pra internet.

- Perfil: o nome que você digitar (é opcional) e o seu nível de experiência no violão.
- Progresso: os acordes que você aprendeu, quantos acordes você acertou, quantos treinos concluiu e a data do último treino.
- Preferências: aparência e cor do app, afinação escolhida (e a personalizada, se você criar uma), tamanho da letra das cifras, se mostra o braço do violão, se a cifra rola sozinha, o modo de reconhecimento, o modelo escolhido e o endereço do servidor.
- Músicas que você cria: nome, artista (opcional), andamento, batida, partes e acordes. Elas ficam só no aparelho, não vão pra lugar nenhum e somem se o app for apagado.

O nome é o único dado pessoal dessa lista, e você só informa se quiser. O resto serve só pra o app funcionar do jeito que você deixou.

## O microfone

O app usa o microfone pra reconhecer os acordes que você toca e pra afinar o violão. Ele só escuta enquanto uma dessas telas está aberta: reconhecer acorde, testar acorde, sequências, tocar junto e afinador.

No modo "No aparelho", que é o padrão, o som é analisado na memória do celular, em pedaços de um segundo e meio que vão sendo substituídos pelos seguintes. O afinador faz o mesmo, com pedaços ainda menores. Nos dois casos o áudio não é gravado em arquivo e não é enviado pra lugar nenhum. O modelo que reconhece os acordes roda dentro do app.

## O modo servidor

O modo "Servidor" é uma opção avançada, desligada por padrão. Ele só funciona se você tiver um computador na mesma rede Wi-Fi rodando o ChordAI-backend, e o endereço desse computador é você quem digita nas configurações.

Nesse modo, o app grava pedaços de um segundo e meio de áudio numa pasta temporária do celular, manda cada pedaço pra esse computador e apaga o arquivo assim que a resposta chega. Se o app fechar no meio de um envio, o arquivo que sobrou é apagado da próxima vez que o modo servidor começa a ouvir. O servidor analisa o áudio na memória, devolve só o nome do acorde e não guarda o áudio.

O áudio vai direto do seu celular pro computador que você configurou, sem passar por mim. A conexão é HTTP, sem criptografia, então outra pessoa na mesma rede Wi-Fi poderia ver esse tráfego. Por isso o app só aceita HTTP pra endereço da rede local (como 192.168.0.10 ou meu-mac.local); pra um endereço fora dela, só HTTPS. Use esse modo só numa rede em que você confia.

## Compartilhamento com terceiros

Hoje o app não manda dados pra nenhum terceiro: não tem Firebase, Google Analytics, anúncio ou qualquer outro serviço externo.

Firebase: ainda não está no app. Quando eu colocar, esta seção vai dizer exatamente quais dados vão pra ele, pra quê e por quanto tempo.

## Por quanto tempo os dados ficam

Os dados ficam no seu aparelho até você apagar. Você pode trocar o nome e o nível no perfil a qualquer momento. Pra apagar tudo, é só limpar os dados do app nas configurações do sistema ou desinstalar o app.

O áudio do microfone não fica guardado: no modo "No aparelho" ele só existe na memória enquanto é analisado, e no modo servidor o arquivo temporário é apagado logo depois do envio.

## Por que o app pode usar esses dados

O microfone só é usado depois que você dá a permissão no sistema (consentimento, art. 7º, I da LGPD), e você pode tirar essa permissão quando quiser nas configurações do aparelho. O nome do perfil é opcional e você mesmo informa. As preferências e o progresso servem só pra entregar o que o app faz.

## Seus direitos

A LGPD (art. 18) garante que você pode confirmar se existe tratamento dos seus dados, acessar, corrigir, apagar e revogar o consentimento. Como os dados ficam só no seu aparelho e eu não recebo nenhum deles, você mesmo consegue fazer tudo isso pelo app e pelas configurações do sistema. Se tiver qualquer dúvida, é só me escrever.

## Permissão do microfone em cada sistema

- iPhone: o sistema pede a permissão na primeira vez que uma tela que escuta é aberta, e dá pra mudar em Ajustes, ChordAI, Microfone.
- Android: o sistema pede a permissão na primeira vez que uma tela que escuta é aberta, e dá pra mudar em Configurações, Apps, ChordAI, Permissões.
- Windows: o Windows não pede permissão por app. Precisa estar ligado "Permitir que aplicativos da área de trabalho acessem o microfone" em Configurações, Privacidade e segurança, Microfone.

## Contato

E-mail: alexandresalg4ado@gmail.com

## Mudanças nesta política

Se eu mudar o que o app faz com os dados, atualizo este texto e a data lá em cima.
