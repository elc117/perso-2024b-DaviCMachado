// Função para criar uma nova sala
async function createRoom() {
    try {
        const response = await fetch('/create-room', { method: 'POST', headers: { 'Content-Type': 'application/json' } });
        const data = await response.json();
        if (response.ok) {
            window.location.href = `game.html?roomId=${data.roomId}`; // Redireciona para a página de jogo
        } else {
            alert(data.error || 'Erro ao criar sala');
        }
    } catch (error) {
        alert('Erro ao criar sala');
    }
}

// Função para entrar em uma sala existente
// Acabou não sendo utilizada
async function joinRoom() {
    const roomId = prompt('Digite o ID da sala para entrar:');
    if (roomId) {
        const response = await fetch(`/join-room/${roomId}`, { method: 'POST', headers: { 'Content-Type': 'application/json' } });
        const data = await response.json();
        if (response.ok) {
            window.location.href = `game.html?roomId=${roomId}`; // Redireciona para a página de jogo
        } else {
            alert(data.error || 'Erro ao entrar na sala');
        }
    }
}

document.addEventListener('DOMContentLoaded', () => {
    document.getElementById('createRoomButton').addEventListener('click', createRoom);
    // document.getElementById('joinRoomButton').addEventListener('click', joinRoom);
});
