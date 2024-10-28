
# Jogo da Velha Online PvE

Nome: Davi de Castro Machado

Curso: Ciência da Computação

Projeto: Jogo da Velha online PvE com criação de salas e armazenamento
de progresso de jogo pelo servidor, permitindo várias sessões de jogo simultâneas.

Objetivo: Desenvolver noções práticas de programação funcional.

Servidor Back-End desenvolvido em Haskell, aproveitando a robustez da programação funcional,
que garante segurança e confiabilidade ao projeto.

Front-End desenvolvido com HTML, CSS e JavaScript.

Processo de Desenvolvimento:

Os principais desafios incluíram: uso de múltiplas bibliotecas,
lógica de rotas e integridade das sessões de jogo.

A comunicação entre cliente e servidor foi desafiadora mas consegui chegar a um resultado
satisfatório, necessitei de fontes como StackOverflow e ChatGPT para compreender partes
do que estava fazendo mas ao final creio que o resultado foi engrandecedor, com um código
conciso e uma bagagem boa de aprendizado sobre programação funcional.

Por fim, o servidor se responsabiliza por gerar salas com IDs únicos para cada sessão de jogo, 
onde o jogador pode sair e eventualmente retornar ao jogo, que manterá o estado salvo e jogável.
Também há uma rota /rooms que mostra todas as salas criadas, em que numa possível atualização
seria útil para modos de jogo multiplayer, com a possibilidade dos jogadores escolherem em qual
sala entrar.

A lógica do jogo ocorre no servidor, limitando o poder de clients maliciosos.

Resultado Final:

![Código Funcionando](GIF.gif)
