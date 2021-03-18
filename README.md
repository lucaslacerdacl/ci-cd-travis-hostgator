# Criando CI-CD com Travis na Hostgator para sites.

## Objetivos:

- Rodar scripts do projeto.
- Automatizar a criação dos artefatos de produção.
- Enviar artefatos gerados para o servidor.

---

## Let's get it on:

- *Acesso SSH no CPanel:*

    → Vamos realizar o envio dos arquivos e executar os scripts através do protocolo ssh. 

    → Para isso, precisamos habilitar um usuário para autenticar em nosso servidor.

    - Escolha um usuário ou crie um novo  para acesso via SSH.
    - Solicitar acesso SSH para o usuário através do e-mail de contato.
    - Criar uma chave SSH no CPanel.
    - [OPCIONAL] → Solicitar acesso apenas com SSH.

---

- *Acesso SSH ao Travis.*

    → Precisamos entregar uma chave privada para dar permissão ao Travis de se comunicar com nosso servidor, no entanto, não podemos publicar nossa chave  privada. 

    → Para resolver essa situação vamos encriptar a nossa chave privada e publicar a chave privada criptografada ao mesmo tempo que passamos a chave de descriptografia para o Travis.

    1. Na sua máquina local, navegue até a pasta do seu projeto.
    2. Crie o arquivo `.travis.yaml` com seus scripts. Não se esqueça de gerar o artefato para publicação, nesse exemplo o comando build cria uma pasta chamada `build` no diretório atual.

        ```yaml
        language: node_js

        node_js:
        - 14

        branches:
          only:
          - master

        before_script:
        - yarn

        script:
        - yarn lint
        - yarn build
        ```

    3. Gere uma chave SSH na sua máquina:
        - `id_rsa_private_name`: Nome da sua chave privada.

        ```bash
        ssh-keygen -t rsa -b 4096 -C 'build@travis-ci.org' -f ./$id_rsa_private_name
        ```

    4. Faça login na CLI do Travis:
        - Caso o login do Travis seja feito pelo GitHub:
            1. Gere um **Personal Access Token** no Github com acesso aos repositórios, copie o token gerado.
            2. Faça login na CLI usando o token:
                - `github_token`: Token copiado no passo anterior.

                ```bash
                travis login --pro --github-token $github_token
                ```

        - Caso contrário faça login com suas credenciais:

            ```bash
            travis login --pro
            ```

    5. Agora vamos encriptar a chave privada que foi gerada:
        - `id_rsa_private_name`: Nome da sua chave privada.
        - `user_name`: Nome do usuário no dashboard do Travis.
        - `project_name`: Nome do projeto a ser entregue.

        ```bash
        travis encrypt-file $id_rsa_private_name --add -r $user_name/$project_name
        ```

    6. A CLI do Travis irá pedir para escrever no arquivo `.travis.yaml` algumas regras, no final ele deve estar parecido com esse exemplo:
        - `domain`: O domínio a ser utilizado.
        - `id_rsa_private_name`: Nome da sua chave privada.

        ```yaml
        addons:
          ssh_known_hosts: $domain

        before_deploy:
        - openssl aes-256-cbc -K $encrypted_xxxxxxxxxxxx_key -iv $encrypted_xxxxxxxxxxxx_iv -in $id_rsa_private_name.enc -out /tmp/$id_rsa_private_name -d
        - eval "$(ssh-agent -s)"
        - chmod 600 /tmp/$id_rsa_private_name
        - ssh-add /tmp/$id_rsa_private_name
        ```

    7. Agora vamos conectar via ssh ao servidor para dar permissão a chave privada que foi gerada:
        - Conexão SSH:
            - `cpanel_ssh_user`: Usuário criado na primeira parte.
            - `domain`: Domínio do seu site.

        ```bash
        ssh $cpanel_ssh_user@$domain
        ```

        - Quando se conectar, abra o arquivo `.ssh/authorized_keys` e cole a chave pública que você gerou no passo 3 desse tópico.

---

- *Enviando arquivos através do SSH:*

    → Vamos trabalhar com dois arquivos de script, um para ser executado no Travis e outro para ser executado dentro do nosso servidor.

    → O script local é responsável por enviar a pasta de artefatos gerados e o script que será executado no servidor para o próprio servidor.

    → O script remoto é responsável por limpar a pasta `public_html` e enviar os artefatos da pasta build para lá, no final  o script deleta pasta vazia e se auto destrói.

    1. Dentro do seu projeto crie uma pasta para armazenar seus scripts chamada `scripts`
    2. Dentro da pasta de scripts crie um arquivo de script chamado  `deploy.local.sh` para ser executado no pipeline do Travis:
        - `cpanel_ssh_user`: Usuário criado na primeira parte.
        - `domain`: Domínio do seu site.

        ```bash
        #!/bin/sh
        echo "[ LOCAL ] | START"
        echo "[ LOCAL ] | SCP BUILD"
        scp -r $TRAVIS_BUILD_DIR/build $cpanel_ssh_user@$domain:/home1/$cpanel_ssh_user/public_html

        echo "[ LOCAL ] | SCP DEPLOY REMOTE FILE"
        scp -r $TRAVIS_BUILD_DIR/scripts/deploy.remote.sh $cpanel_ssh_user@$domain:/home1/$cpanel_ssh_user

        echo "[ LOCAL ] | EXECUTE DEPLOY REMOTE FILE"
        ssh $cpanel_ssh_user@$domain 'chmod 777 deploy.remote.sh'
        ssh $cpanel_ssh_user@$domain 'sh deploy.remote.sh'
        echo "[ LOCAL ] | FINISH"
        ```

    3. Dentro da pasta de scripts crie um arquivo de script chamado `deploy.remote.sh` para ser executado dentro do servidor:

        ```bash
        #!/bin/sh
        echo "[ REMOTE ] | START"

        cd public_html

        folders=("static")
        files=(
          "_redirects"
          "asset-manifest.json"
          "favicon.ico"
          "index.html"
          "logo192.png"
          "logo512.png"
          "manifest.json"
          "precache-manifest.*.js"
          "robots.txt"
          "service-worker.js"
        )

        echo "[ REMOTE ] | Delete folders"
        for folder in ${folders[@]}
        do
          rm -rf -v $folder
        done

        echo "[ REMOTE ] | Delete files"
        for file in ${files[@]}
        do
          rm -rf -v $file
        done

        echo "[ REMOTE ] | Moving files"
        mv -v build/* ./

        echo "[ REMOTE ] | Clean Deploy"
        rm -rf build
        rm ../deploy.remote.sh

        echo "[ REMOTE ] | FINISH"
        ```

---

- *Executando o deploy no Travis:*

    → Por fim informamos ao Travis para executar nosso script local quando houver commit na master.

    1. No seu arquivo `travis.yaml` adicione o campo para deploy:

        ```yaml
        deploy:
          provider: script
          skip_cleanup: true
          script: sh scripts/deploy.local.sh
          on:
            branch: master
        ```

---

### Referências

[SSH deploys with Travis CI](https://oncletom.io/2016/travis-ssh-deploy/)

[How to copy files via SSH - PragmaticLinux](https://www.pragmaticlinux.com/2020/07/how-to-copy-files-via-ssh/)

[How to Use SSH Public Key Authentication](https://serverpilot.io/docs/how-to-use-ssh-public-key-authentication/)

---
