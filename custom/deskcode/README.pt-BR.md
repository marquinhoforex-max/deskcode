# DeskCode com Google Gemini

Esta personalização usa a base atual do OpenCode e configura o Google Gemini como provedor padrão. Ela não altera números internos para fingir uma janela de contexto maior que a aceita pelo modelo.

## O que está configurado

- Modelo principal e modelo leve: `google/gemini-2.5-flash`.
- Gemini permanece como padrão, mas os demais provedores não são bloqueados.
- Compactação automática antes do estouro de contexto.
- Poda de saídas antigas de ferramentas.
- Reserva de 20.000 tokens para permitir que a compactação termine.
- Preservação de até 15.000 tokens e 50 turnos recentes, respeitando o espaço disponível.

O OpenCode já implementa compactação em `packages/opencode/src/session/compaction.ts` e calcula o espaço utilizável em `packages/opencode/src/session/overflow.ts`. Esta configuração reutiliza esses mecanismos nativos.

## Segurança primeiro

A chave exibida anteriormente deve permanecer revogada. Gere uma chave nova e nunca a coloque em commits, issues ou mensagens.

O repositório já ignora arquivos `.env`. O exemplo usa a variável reconhecida pelo provedor Google:

```text
GOOGLE_GENERATIVE_AI_API_KEY=coloque_sua_nova_chave_aqui
```

## Modelos gratuitos e outros provedores

O DeskCode não restringe a lista de provedores. Sem autenticação adicional, o OpenCode pode exibir modelos públicos gratuitos disponibilizados pelo serviço OpenCode. Ao conectar outras contas ou definir as respectivas chaves, os provedores compatíveis também ficam disponíveis no seletor de modelos.

A disponibilidade gratuita muda ao longo do tempo e pode depender da conta, região, cota e termos de cada provedor. Confirme no seletor e na página oficial de preços antes de usar. Habilitar um provedor não transforma modelos pagos em gratuitos e não impede cobranças em contas que já tenham faturamento ativo.

O Gemini continua sendo o modelo inicial e requer `GOOGLE_GENERATIVE_AI_API_KEY`. Use o seletor de modelos do aplicativo para trocar para outra opção disponível.

## Baixar o pacote pronto

O workflow `DeskCode Windows` compila o aplicativo em um runner Windows e publica o artefato `DeskCode-Windows-x64`. Na página do GitHub, abra **Actions**, selecione o workflow e baixe o ZIP na seção **Artifacts** da execução concluída.

Extraia o ZIP e execute:

```powershell
.\deskcode.ps1
```

Na primeira execução, o launcher solicita uma chave Gemini nova de forma mascarada e a grava somente no arquivo `.env` ao lado do executável. O arquivo não é enviado ao GitHub.

## Build no Windows

Instale Git e Bun, clone seu fork e execute:

```powershell
git clone https://github.com/marquinhoforex-max/deskcode.git
cd deskcode
git checkout dev
.\script\build-deskcode.ps1
```

Por padrão, os arquivos são instalados em `%LOCALAPPDATA%\DeskCode`. Edite o arquivo `.env` criado nessa pasta e depois inicie:

```powershell
& "$env:LOCALAPPDATA\DeskCode\deskcode.ps1"
```

Para escolher outra pasta:

```powershell
.\script\build-deskcode.ps1 -InstallDirectory "C:\Users\Marcos\Documents\PROJETO 0\DeskCode"
```

## Limites reais

Não existe uma alteração local capaz de remover os limites impostos pelo Gemini. A janela de contexto, o máximo de saída, as cotas e os rate limits são controlados pelo provedor. Declarar valores maiores no cliente pode causar rejeições da API e perda de contexto.

A estratégia adotada é usar todo o espaço anunciado pelo modelo e compactar a conversa automaticamente antes do limite. Erros transitórios e respostas HTTP 429 continuam sendo tratados pelo mecanismo de retry do provedor, respeitando as orientações de espera retornadas pela API.
