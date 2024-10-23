let currentRoomId = null;
let board = Array(3).fill(null).map(() => Array(3).fill(null)); // Inicializa o tabuleiro como uma matriz 3x3

// Função para buscar o estado do tabuleiro
async function fetchBoard() {
    try {
        const response = await fetch(`/game-state/${currentRoomId}`);
        const data = await response.json();

        if (response.ok) {
            board = data.board; // Atualiza o tabuleiro localmente
            renderBoard(); // Renderiza o tabuleiro
        } else {
            alert(data.error || 'Erro ao buscar o estado do tabuleiro');
        }
    } catch (error) {
        console.error('Erro ao buscar o estado do tabuleiro:', error);
        alert('Erro ao buscar o estado do tabuleiro');
    }
}

// Função para renderizar o tabuleiro
function renderBoard() {
    const boardDiv = document.getElementById('board');
    boardDiv.innerHTML = ''; // Limpa o tabuleiro anterior

    board.forEach((row, rowIndex) => {
        row.forEach((cell, colIndex) => {
            const cellDiv = document.createElement('div');
            cellDiv.className = 'cell';
            cellDiv.id = `cell-${rowIndex}-${colIndex}`; // Adiciona um ID a cada célula
            cellDiv.textContent = cell ? cell : ''; // Exibe X, O ou vazio
            cellDiv.addEventListener('click', () => makeMove(rowIndex, colIndex));
            boardDiv.appendChild(cellDiv);
        });
    });
}

async function makeMove(row, col) {
    try {
        const response = await fetch(`/play/${currentRoomId}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify([row, col]), // Envia a jogada como array
        });

        const data = await response.json();

        if (response.ok) {
            board = data.board; // Atualiza o tabuleiro com o novo estado
            renderBoard(); // Renderiza o novo estado do tabuleiro
            const messageDiv = document.getElementById('message'); // Obtém o elemento da mensagem
            
            if (data.winner) {
                messageDiv.textContent = `O jogador ${data.winner} venceu!`; // Exibe a mensagem de vitória
            } else if (isDraw()) { // Verifica se é empate
                messageDiv.textContent = 'Empate!'; // Exibe a mensagem de empate
            } else {
                messageDiv.textContent = ''; // Limpa a mensagem se não houver vencedor
            }
        }        
    } catch (error) {
        console.error('Erro ao fazer a jogada:', error);
        alert('Erro ao fazer a jogada');
    }
}

// Função para verificar se o jogo terminou em empate
function isDraw() {
    return board.every(row => row.every(cell => cell !== null)); // Retorna true se todas as células estiverem preenchidas
}


async function restartGame() {
    try {
        const response = await fetch(`/restart/${currentRoomId}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            }
        });

        const data = await response.json();

        const messageDiv = document.getElementById('message'); // Obtém o elemento da mensagem
        if (response.ok) {
            resetBoard(); // Reinicia o tabuleiro
            // messageDiv.textContent = data.message || 'Jogo reiniciado com sucesso!'; // Exibe a mensagem de sucesso
        } else {
            messageDiv.textContent = data.error || 'Erro ao reiniciar o jogo'; // Exibe a mensagem de erro
        }
    } catch (error) {
        console.error('Erro ao reiniciar o jogo:', error);
        document.getElementById('message').textContent = 'Erro ao reiniciar o jogo'; // Exibe a mensagem de erro na tela
    }
}


// Função para reiniciar o tabuleiro localmente
function resetBoard() {
    board = Array(3).fill(null).map(() => Array(3).fill(null)); // Reinicia o tabuleiro como matriz 3x3
    renderBoard(); // Renderiza o tabuleiro reiniciado
    document.getElementById('message').textContent = ''; // Limpa a mensagem
}

document.addEventListener('DOMContentLoaded', () => {
    // Obtém o ID da sala a partir dos parâmetros da URL
    const params = new URLSearchParams(window.location.search);
    currentRoomId = params.get('roomId');

    if (!currentRoomId) {
        alert('ID da sala não encontrado! Retornando à página inicial.');
        window.location.href = 'index.html';
    } else {
        fetchBoard(); // Busca o estado inicial do tabuleiro
        document.getElementById('restartGameButton').addEventListener('click', restartGame);
    }
});
