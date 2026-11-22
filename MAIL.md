# Gmail no Prelude

Conta: comercial.bertholino@gmail.com. Cliente: Gnus, incluído no Emacs.

## Abrir e escrever

- Abra **Prelude Mail** no lançador de aplicativos.
- `C-c m`: abrir o e-mail.
- `C-c M`: escrever uma mensagem.
- Links `mailto:` do navegador abrem o compositor do Prelude.
- Para enviar a mensagem que você revisou: `C-c C-c` e confirme o envio.
- Para anexar um arquivo no compositor: `C-c C-a`.

Na lista de pastas, `RET` abre a pasta, `g` atualiza e `L` mostra pastas que não têm mensagens não lidas. `A A` lista todas as pastas do servidor; `u` altera a assinatura da pasta sob o cursor. INBOX fica visível mesmo vazia. Dentro da pasta, `RET` abre a mensagem, `r` responde e `C-c C-f` encaminha. `q` retorna à tela anterior. O Gnus verifica novas mensagens a cada cinco minutos enquanto estiver aberto.

Os buffers de navegação do Gnus usam os atalhos próprios do aplicativo; a edição de mensagens mantém sua configuração de edição existente. Se houver uma seleção ativa, CUA pode usar `C-c` para copiar; desative a seleção antes das sequências de comandos.

## Autenticação

O Gmail usa uma senha de app de 16 letras gerada em:
https://myaccount.google.com/apppasswords

Isso pode exigir verificação em duas etapas. Não use a senha principal da conta.

`M-x my/prelude-mail-setup` abre o campo protegido para cadastrar ou substituir a senha. As entradas IMAP e SMTP ficam na coleção **Login** do GNOME Keyring, criptografadas em disco, acessadas por `auth-source`. Não são gravadas nos arquivos de configuração, histórico de comandos ou Git. Ao substituir a senha, as entradas anteriores criadas por esta integração são removidas.

Leitura: imap.gmail.com:993 com TLS. Envio: smtp.gmail.com:465 com TLS. O Gmail guarda as mensagens enviadas automaticamente, sem uma segunda cópia pelo Gnus.

## Arquivos

- Configuração: `modules/mail.el`.
- Lançador: `~/.local/bin/prelude-mail`.
- Aplicativo padrão: `~/.local/share/applications/prelude-mail.desktop`.
- Estado e rascunhos locais: `~/.local/share/prelude-mail/`, diretório privado e ignorado pelo Git dos dotfiles.

Os corpos das mensagens e rascunhos locais não são criptografados por esta configuração; a criptografia do chaveiro protege as credenciais. Imagens remotas são bloqueadas na leitura. O compositor interpreta os links mailto com o parser UTF-8 nativo do Emacs, incluindo assunto e texto com acentos e símbolos matemáticos.
