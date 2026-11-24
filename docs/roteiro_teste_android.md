# Roteiro de teste no Android

Roteiro para testar o ChordAI num Android de verdade antes de mostrar o app. Vale para um celular que nunca teve o app e para quem atualiza de uma versão anterior.

Material necessário:

- um Android 7.0 ou mais novo (o `minSdk` do app é 24);
- um violão;
- um lugar sem muito barulho;
- o QR Code impresso, ou o link da Wiki: https://github.com/imxder/ChordAI/wiki/Baixar.

Em cada passo, marque o que aconteceu. Se algo der errado, anote o modelo do celular, a versão do Android, a tela e o que foi feito logo antes.

## 1. Instalação pelo QR Code

- [ ] Leia o QR Code com a câmera e confira que abre a página Baixar da Wiki.
- [ ] Confira que o selo da página mostra a versão mais nova.
- [ ] Toque no link e confira que o download do `ChordAI.apk` começa.
- [ ] Abra o arquivo. Se o Android pedir, libere "instalar apps desconhecidos" para o navegador ou para o
      gerenciador de arquivos.
- [ ] Se o Play Protect avisar, vá em "Mais detalhes" e depois "Instalar assim mesmo".
- [ ] Confira que o ChordAI aparece na lista de apps, com o ícone certo.

Se o celular já tinha um ChordAI instalado por cabo (`flutter run` ou `adb`), o Android recusa a atualização, porque a chave é outra. Nesse caso, desinstale o antigo antes. Os dados desse aparelho se perdem.

## 2. Primeiro uso

- [ ] Abra o app e confira que aparecem as páginas de apresentação. "Pular" e "Certo" têm que funcionar.
- [ ] Confira que no fim aparece "Seu violão está afinado?".
- [ ] "Afinar agora" tem que abrir o afinador, e "Já está afinado" tem que ir para o Início.
- [ ] Feche o app e abra de novo: ele tem que ir direto para o Início, sem repetir a apresentação.

## 3. Permissão do microfone

- [ ] Na primeira tela que usa o microfone, confira que o Android pergunta se pode gravar áudio.
- [ ] Negue a permissão e confira que a tela mostra "O app precisa de acesso ao microfone" e não trava.
- [ ] Libere nas Configurações do Android, volte para o app e confira que o afinador já funciona, sem precisar
      fechar o app.

## 4. Afinador

No Início, toque em Afinador.

- [ ] Com "Reconhecer a corda sozinho" ligado, toque cada corda solta. A casinha certa tem que acender e o
      ponteiro aparecer logo, sem atraso.
- [ ] Aperte ou afrouxe a tarraxa e confira que o ponteiro acompanha. Ele fica verde e mostra "Afinada" quando
      chega na nota.
- [ ] Deixe a corda soar até sumir: o ponteiro tem que continuar na corda por uns segundos e não pular para
      outra.
- [ ] Toque uma corda e logo depois outra: o afinador tem que trocar para a corda nova.
- [ ] Desligue "Reconhecer a corda sozinho" e toque numa casinha. O ponteiro só mede aquela corda,
      mesmo se outra for tocada.
- [ ] Confira que os números embaixo das casinhas vão de 6ª (a mais grossa) a 1ª (a mais fina).
- [ ] Confira que "Primeira vez?" abre o guia com o desenho das cordas.
- [ ] Troque a afinação em "Afinação" e confira que as casinhas mudam de nota.

## 5. Reconhecer acorde

O modelo conhece estes acordes: C, Dm, Em, F, G, Am, Bb e Bdim. O modelo "v3 + meu dataset" também
conhece o A. Os nomes vêm de `assets/models/*/labels.json`.

- [ ] No Início, toque em Reconhecer acorde e depois em Ouvir.
- [ ] Faça cada acorde da lista e deixe soar. O nome que aparece tem que ser o acorde tocado.
- [ ] Abafe as cordas ou fale: o app não pode inventar acorde.
- [ ] Toque em Parar e confira que o microfone desliga (no Android 12 ou mais novo, o aviso verde de microfone some).
- [ ] Ligue o modo avião e repita: o app continua reconhecendo, porque o modelo roda no celular.

## 6. Aprender acordes

- [ ] Na aba Acordes, abra um acorde e toque em "Tocar e testar".
- [ ] Toque em Começar e faça o acorde: o contador de acertos seguidos tem que subir.
- [ ] Com 3 acertos seguidos, o acorde tem que ficar marcado como aprendido, na lista e em "Seus acordes", na tela inicial.
- [ ] Faça outro acorde: tem que aparecer "Ouvi X. Tente de novo" e o contador zerar.

## 7. Sequências

- [ ] Na tela inicial, toque em Tocar músicas e abra Sequências de acordes.
- [ ] Escolha uma sequência, ajuste o andamento e toque em Começar.
- [ ] Confira que o metrônomo marca o tempo com o clique (o tempo 1 mais agudo) e que os acertos aparecem enquanto o acorde é tocado.
- [ ] Confira que no fim aparece "Treino concluído" com o número de acertos.

## 8. Tocar junto

- [ ] Na tela inicial, toque em Tocar músicas e abra Riptide ou All Too Well: tem que abrir direto o tocar junto.
- [ ] Toque em Começar: tem que aparecer a contagem com o clique e depois o acorde a tocar.
- [ ] Confira que os acertos aparecem enquanto o acorde é tocado e que no fim aparece o "Resumo da música".
- [ ] No Aa, desligue "Ouvir pelo microfone" e toque em Começar: a cifra tem que andar no tempo, o aviso de microfone não pode aparecer e no fim não pode ter resumo.
- [ ] No Aa, desligue "Som do metrônomo": o clique tem que sumir aqui e nas Sequências.

## 8b. Sons

- [ ] No afinador, quando a corda ficar afinada, confira que toca o "di-ding" uma vez e que o ponteiro não pula.
- [ ] Em Tocar e testar, quando o acorde virar aprendido, confira que toca o som, o microfone desliga e aparece "Ver meus acordes".
- [ ] Em Configurações, desligue Sons: nenhum dos três sons pode tocar.

## 9. Segundo plano e tela bloqueada

Em cada tela com microfone (afinador, Reconhecer acorde, Tocar e testar, Sequências e Tocar junto):

- [ ] Com o microfone ligado, vá para a tela inicial do Android: no Android 12 ou mais novo, o aviso de microfone some da barra de
      cima.
- [ ] Bloqueie o celular e desbloqueie: o app não pode travar.
- [ ] Confira que o afinador volta a ouvir sozinho, e que Reconhecer acorde, Tocar e testar e Sequências voltam parados,
      esperando o toque em Ouvir ou Começar.
- [ ] No Tocar junto, bloqueie no meio da música. Quando voltar, a música tem que continuar de onde parou.

## 10. Configurações e dados guardados

- [ ] Na tela inicial, confira que a engrenagem no canto do título abre as Configurações.
- [ ] Troque a cor do app e a aparência (claro e escuro): todas as telas têm que mudar.
- [ ] Feche o app pelos recentes e abra de novo: a cor, a aparência, os acordes aprendidos e as
      músicas criadas têm que continuar lá.
- [ ] Confira que "Privacidade" abre o texto da política.

## 11. Atualização

Num celular que já tem uma versão instalada pelo QR Code:

- [ ] Instale a versão nova pelo mesmo link, por cima da antiga, sem desinstalar.
- [ ] Confira que os acordes aprendidos, as músicas e as preferências continuam lá.

## Pronto quando

O app instala pelo QR Code num Android que nunca teve o app e reconhece um acorde.
