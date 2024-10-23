{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE StrictData #-}

import Web.Scotty
import GHC.Generics (Generic)
import Data.Aeson (ToJSON, FromJSON)
import Data.Text.Lazy (Text)
import Control.Monad.IO.Class (liftIO)
import qualified Data.Map as Map
import Data.IORef
import Control.Applicative (ZipList(..), getZipList)
import Network.Wai.Middleware.Static
import System.Random (randomRIO)
import Data.Char (chr)
import qualified Control.Monad
import qualified Data.Maybe
import Data.Foldable
-- Definindo os tipos para o jogo
data Cell = X | O deriving (Show, Eq, Generic)
instance ToJSON Cell
instance FromJSON Cell

type Board = [[Maybe Cell]]

data GameState = GameState
  { board :: Board
  , currentPlayer :: Cell
  , gameOver :: Bool
  , winner :: Maybe Cell -- Adicionando um campo para armazenar o vencedor
  } deriving (Show, Generic)

instance ToJSON GameState
instance FromJSON GameState

type RoomId = String
type GameRooms = Map.Map RoomId GameState
type ServerState = IORef GameRooms

-- Funções auxiliares
initialBoard :: Board
initialBoard = replicate 3 (replicate 3 Nothing)

initialState :: GameState
initialState = GameState
  { board = initialBoard
  , currentPlayer = X
  , gameOver = False
  , winner = Nothing
  }


-- Função para gerar um ID de sala único
generateRoomId :: GameRooms -> IO String
generateRoomId gameRooms = do
  newId <- randomRoomId
  if Map.member newId gameRooms
    then generateRoomId gameRooms -- Se o ID já existe, tenta novamente
    else return newId
  where
    -- Gera um ID aleatório para a sala
    randomRoomId :: IO String
    randomRoomId = Control.Monad.replicateM 6 (randomChar ())

    -- Gera um caractere aleatório (letra maiúscula ou minúscula)
    randomChar _ = do
      n <- randomRIO (0, 51) -- 26 letras maiúsculas + 26 letras minúsculas
      return $ chr (if n < 26 then n + 65 else n + 97 - 26)


-- Atualizar o estado do jogo com uma jogada
updateGameState :: GameState -> (Int, Int) -> GameState
updateGameState game (row, col)
  | gameOver game = game -- Se o jogo acabou, não faz nada
  | not (isValidMove (board game) (row, col)) = game -- Jogada inválida, não faz nada
  | otherwise =
      let b = board game
          player = currentPlayer game
          newBoard = updateBoard b (row, col) player
          newPlayer = if player == X then O else X
          newGameOver = checkGameOver newBoard
          newWinner = if newGameOver && Data.Maybe.isJust (checkWinner newBoard) then checkWinner newBoard else Nothing
      in GameState
          { board = newBoard
          , currentPlayer = newPlayer
          , gameOver = newGameOver || isBoardFull newBoard
          , winner = newWinner
          }
-- Verifica se a jogada é válida (a célula está vazia)
isValidMove :: Board -> (Int, Int) -> Bool
isValidMove b (row, col) = case safeIndex row col b of
  Just Nothing -> True  -- A célula está vazia
  _            -> False -- A célula está ocupada ou fora dos limites

-- Atualiza a função safeIndex para retornar Maybe
safeIndex :: Int -> Int -> [[a]] -> Maybe a
safeIndex i j b
  | i < 0 || i >= length b || j < 0 || j >= length (b !! i) = Nothing
  | otherwise = Just ((b !! i) !! j)

-- Atualiza o tabuleiro com a jogada
updateBoard :: Board -> (Int, Int) -> Cell -> Board
updateBoard b (row, col) player =
  [ [if i == row && j == col then Just player else b !! i !! j | j <- [0..2]]
  | i <- [0..2]]

-- Verifica se todas as células estão preenchidas (empate)
isBoardFull :: Board -> Bool
isBoardFull = all (notElem Nothing)  -- Verifica se não há células vazias (Nothing)

-- Verifica se o jogo acabou
checkGameOver :: Board -> Bool
checkGameOver b = any isWinningLine (rows ++ cols ++ diags) || isBoardFull b
  where
    rows = b
    cols = transpose b
    diags = [[b !! i !! i | i <- [0..2]], [b !! i !! (2 - i) | i <- [0..2]]]
    isWinningLine line = all (== Just X) line || all (== Just O) line

-- Retorna o vencedor, se houver
checkWinner :: Board -> Maybe Cell
checkWinner b
  | any (all (== Just X)) (rows ++ cols ++ diags) = Just X
  | any (all (== Just O)) (rows ++ cols ++ diags) = Just O
  | otherwise = Nothing
  where
    rows = b
    cols = transpose b
    diags = [[b !! i !! i | i <- [0..2]], [b !! i !! (2 - i) | i <- [0..2]]]

-- Função para transpor a matriz (para verificar colunas)
transpose :: [[a]] -> [[a]]
transpose = getZipList . traverse ZipList

-- Verifica se uma jogada levará à vitória
canWinWithMove :: Board -> Cell -> (Int, Int) -> Bool
canWinWithMove b player (row, col) =
    let newBoard = updateBoard b (row, col) player
    in checkWinner newBoard == Just player

-- Função para a IA escolher a melhor jogada
chooseBestMove :: Board -> Cell -> Maybe (Int, Int)
chooseBestMove b player =
    -- 1. Tentar vencer
    case find (canWinWithMove b player) emptyCells of
        Just winMove -> Just winMove
        Nothing ->
            -- 2. Bloquear o jogador
            case find (canWinWithMove b (opponent player)) emptyCells of
                Just blockMove -> Just blockMove
                Nothing ->
                    -- 3. Jogada estratégica: centro, cantos, laterais
                    find (`elem` preferredMoves) emptyCells
  where
    emptyCells = [(i, j) | i <- [0..2], j <- [0..2], b !! i !! j == Nothing]
    opponent X = O
    opponent O = X
    preferredMoves = [(1, 1), (0, 0), (0, 2), (2, 0), (2, 2), (0, 1), (1, 0), (1, 2), (2, 1)] -- Centro, cantos e laterais em ordem de prioridade

-- Atualizar o estado do jogo com a jogada da IA
updateGameStateWithSimpleAI :: GameState -> (Int, Int) -> IO GameState
updateGameStateWithSimpleAI game (row, col)
    | gameOver game = return game -- Se o jogo acabou, não faz nada
    | not (isValidMove (board game) (row, col)) = return game -- Jogada inválida, não faz nada
    | otherwise = do
        -- Atualiza o estado do jogo com a jogada do jogador
        let player = currentPlayer game
        let newBoard = updateBoard (board game) (row, col) player
        let newGameOver = checkGameOver newBoard
        let newWinner = if newGameOver then checkWinner newBoard else Nothing
        let gameAfterPlayerMove = game { board = newBoard, currentPlayer = if player == X then O else X, gameOver = newGameOver, winner = newWinner }

        -- Se o jogo acabou após a jogada do jogador, retorna o novo estado
        if newGameOver then return gameAfterPlayerMove
        else do
            -- Caso contrário, a IA faz uma jogada
            let aiPlayer = currentPlayer gameAfterPlayerMove
            case chooseBestMove newBoard aiPlayer of
                Just (aiRow, aiCol) -> do
                    let boardAfterAIMove = updateBoard newBoard (aiRow, aiCol) aiPlayer
                    let gameOverAfterAIMove = checkGameOver boardAfterAIMove
                    let winnerAfterAIMove = if gameOverAfterAIMove then checkWinner boardAfterAIMove else Nothing
                    return gameAfterPlayerMove
                        { board = boardAfterAIMove
                        , currentPlayer = if aiPlayer == X then O else X
                        , gameOver = gameOverAfterAIMove
                        , winner = winnerAfterAIMove
                        }
                Nothing -> return gameAfterPlayerMove -- Se não houver jogada válida, retorna o estado atual



-- Função principal do servidor
main :: IO ()
main = do
  rooms <- newIORef Map.empty
  scotty 3000 $ do

    middleware $ staticPolicy (addBase "public") -- Serve arquivos estáticos da pasta "static"

    get "/" $ do
      file "public/index.html"
      --file "public/index.html" -- Serve o arquivo HTML

    post "/create-room" $ do
        gameRooms <- liftIO $ readIORef rooms
        roomId <- liftIO $ generateRoomId gameRooms
        liftIO $ modifyIORef' rooms (Map.insert roomId initialState)
        json $ Map.singleton ("roomId" :: Text) roomId


    post "/join-room/:roomId" $ do
      roomId <- param "roomId"
      gameRooms <- liftIO $ readIORef rooms
      case Map.lookup roomId gameRooms of
        Just _ -> json $ Map.singleton ("status" :: Text) ("Joined room " ++ roomId)
        Nothing -> json $ Map.singleton ("error" :: Text) ("Room not found" :: Text)

    get "/game-state/:roomId" $ do
      roomId <- param "roomId"
      gameRooms <- liftIO $ readIORef rooms
      case Map.lookup roomId gameRooms of
        Just state -> json state
        Nothing -> json $ Map.singleton ("error" :: Text) ("Room not found" :: Text)

    post "/play/:roomId" $ do
      roomId <- param "roomId"
      gameRooms <- liftIO $ readIORef rooms
      case Map.lookup roomId gameRooms of
          Just state -> do
              move <- jsonData :: ActionM (Int, Int)
              let newState = updateGameState state move
              liftIO $ modifyIORef' rooms (Map.insert roomId newState)

              -- Verifica se o jogo acabou após a jogada do jogador
              if gameOver newState
                  then json newState -- Retorna o estado se o jogo já tiver acabado
                  else do
                      -- A IA faz sua jogada
                      let aiMove = chooseBestMove (board newState) (currentPlayer newState)
                      case aiMove of
                          Just (aiRow, aiCol) -> do
                              let stateAfterAIMove = updateGameState newState (aiRow, aiCol)
                              liftIO $ modifyIORef' rooms (Map.insert roomId stateAfterAIMove)
                              json stateAfterAIMove -- Retorna o estado após a jogada da IA
                          Nothing -> json newState -- Se não houver jogada válida para a IA, retorna o estado atual
          Nothing -> json $ Map.singleton ("error" :: Text) ("Room not found" :: Text)


    -- Rota para listar as salas existentes
    get "/rooms" $ do
        gameRooms <- liftIO $ readIORef rooms
        let roomIds = Map.keys gameRooms
        json roomIds

    -- Rota para reiniciar o jogo
    post "/restart/:roomId" $ do
        roomId <- param "roomId"
        gameRooms <- liftIO $ readIORef rooms
        case Map.lookup roomId gameRooms of 
            Just _ -> do
                -- Reinicia o jogo para a sala
                liftIO $ modifyIORef' rooms (Map.insert roomId initialState)
                json $ Map.singleton ("message" :: Text) ("Jogo reiniciado com sucesso na sala " ++ roomId)
            Nothing -> json $ Map.singleton ("error" :: Text) ("Room not found" :: Text)
