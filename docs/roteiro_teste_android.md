# Roteiro de teste no Android

O roteiro que eu sigo pra testar o ChordAI num Android de verdade antes de mostrar o app. Vale pra
um celular que nunca teve o app e pra quem atualiza de uma versão anterior.

Preciso de:

- um Android 7.0 ou mais novo (o `minSdk` do app é 24);
- um violão;
- um lugar sem muito barulho;
- o QR Code impresso, ou o link da Wiki: https://github.com/imxder/ChordAI/wiki/Baixar.

Em cada passo eu marco o que aconteceu. Se algo der errado, anoto o modelo do celular, a versão do
Android, a tela e o que eu fiz logo antes.

## 1. Instalação pelo QR Code

- [ ] Leio o QR Code com a câmera e abre a página Baixar da Wiki.
- [ ] O selo da página mostra a versão mais nova.
- [ ] Toco no link e o download do `ChordAI.apk` começa.
- [ ] Abro o arquivo. Se o Android pedir, libero "instalar apps desconhecidos" pro navegador ou pro
      gerenciador de arquivos.
- [ ] Se o Play Protect avisar, vou em "Mais detalhes" e depois "Instalar assim mesmo".
- [ ] O ChordAI aparece na lista de apps, com o ícone certo.

Se o celular já tinha um ChordAI instalado por cabo (`flutter run` ou `adb`), o Android recusa a
atualização, porque a chave é outra. Nesse caso desinstalo o antigo antes. Os dados desse aparelho
se perdem.

## 2. Primeiro uso

- [ ] Abro o app e aparecem as páginas de apresentação. "Pular" e "Certo" funcionam.
- [ ] No fim aparece "Seu violão está afinado?".
- [ ] "Afinar agora" abre o afinador. "Já está afinado" vai pro Início.
- [ ] Fecho o app e abro de novo: ele vai direto pro Início, sem repetir a apresentação.

## 3. Permissão do microfone

- [ ] Na primeira tela que usa o microfone, o Android pergunta se pode gravar áudio.
- [ ] Se eu nego, a tela mostra "O app precisa de acesso ao microfone" e não trava.
- [ ] Libero nas Configurações do Android, volto pro app e o afinador já funciona, sem precisar
      fechar o app.

## 4. Afinador

No Início, toco em Afinador.

- [ ] Com "Reconhecer a corda sozinho" ligado, toco cada corda solta. A casinha certa acende e o
      ponteiro aparece logo, sem atraso.
- [ ] Apertando ou afrouxando a tarraxa, o ponteiro acompanha. Fica verde e mostra "Afinada" quando
      chega na nota.
- [ ] Deixo a corda soar até sumir: o ponteiro continua na corda por uns segundos e não pula pra
      outra.
- [ ] Toco uma corda e logo depois outra: o afinador troca pra corda nova.
- [ ] Desligo "Reconhecer a corda sozinho" e toco numa casinha. O ponteiro só mede aquela corda,
      mesmo se eu tocar outra.
- [ ] Os números embaixo das casinhas vão de 6ª (a mais grossa) a 1ª (a mais fina).
- [ ] "Primeira vez?" abre o guia com o desenho das cordas.
- [ ] Troco a afinação em "Afinação" e as casinhas mudam de nota.

## 5. Reconhecer acorde

O modelo conhece estes acordes: C, Dm, Em, F, G, Am, Bb e Bdim. O modelo "v3 + meu dataset" também
conhece o A. Os nomes vêm de `assets/models/*/labels.json`.

- [ ] No Início, toco em Reconhecer acorde e depois em Ouvir.
- [ ] Faço cada acorde da lista e deixo soar. O nome que aparece é o que eu toquei.
- [ ] Abafando as cordas ou falando, ele não inventa acorde.
- [ ] Parar desliga o microfone (no Android 12 ou mais novo, o aviso verde de microfone some).
- [ ] Ligo o modo avião e repito: continua reconhecendo, porque o modelo roda no celular.

## 6. Aprender acordes

- [ ] Na aba Acordes, abro um acorde e toco em "Tocar e testar".
- [ ] Toco em Começar e faço o acorde: o contador de acertos seguidos sobe.
- [ ] Com 3 acertos seguidos o acorde fica marcado como aprendido, na lista e no Perfil.
- [ ] Fazendo outro acorde, aparece "Ouvi X. Tente de novo" e o contador zera.

## 7. Sequências

- [ ] Na aba Músicas, abro Sequências de acordes.
- [ ] Escolho uma sequência, ajusto o andamento e toco em Começar.
- [ ] O metrônomo marca o tempo e os acertos aparecem enquanto eu toco.
- [ ] No fim aparece "Treino concluído" com o número de acertos, e o Perfil atualiza "Treinos
      concluídos" e "Último treino".

## 8. Tocar junto

- [ ] Na aba Músicas, abro Riptide ou All Too Well.
- [ ] A cifra rola sozinha. Os botões de velocidade mudam a rolagem.
- [ ] Toco em Tocar junto e depois em Começar: aparece a contagem e depois o acorde a tocar.
- [ ] Os acertos aparecem enquanto eu toco. No fim aparece o "Resumo da música".

## 9. Segundo plano e tela bloqueada

Em cada tela com microfone (afinador, Reconhecer acorde, Tocar e testar, Sequências e Tocar junto):

- [ ] Com o microfone ligado, vou pra tela inicial do Android: no Android 12 ou mais novo, o aviso de microfone some da barra de
      cima.
- [ ] Bloqueio o celular e desbloqueio: o app não trava.
- [ ] O afinador volta a ouvir sozinho. Reconhecer acorde, Tocar e testar e Sequências voltam parados,
      esperando eu tocar em Ouvir ou Começar.
- [ ] No Tocar junto, bloqueio no meio da música. Quando volto, a música continua de onde parou.

## 10. Perfil e dados guardados

- [ ] No Perfil, preencho o nome e a experiência com violão.
- [ ] Troco a cor do app e a aparência (claro e escuro): todas as telas mudam.
- [ ] Fecho o app pelos recentes e abro de novo: nome, cor, acordes aprendidos e treinos
      continuam lá.
- [ ] "Privacidade" abre o texto da política.

## 11. Atualização

Num celular que já tem uma versão instalada pelo QR Code:

- [ ] Instalo a versão nova pelo mesmo link, por cima da antiga, sem desinstalar.
- [ ] Os acordes aprendidos, o perfil e os treinos continuam lá.

## Pronto quando

O app instala pelo QR Code num Android que nunca teve o app e reconhece um acorde.
