{-# LANGUAGE OverloadedStrings #-}

module Game.SaveLoad 
    ( saveGame
    , loadGame
    ) where

import Control.Exception (try, SomeException)
import System.Directory (createDirectoryIfMissing, doesFileExist)
import Data.Aeson (encode, decode)
import qualified Data.ByteString.Lazy as B
import Game.Estrutura (GameState(..))

-- Diretório base para salvar os arquivos
baseDir :: FilePath
baseDir = "data/saves"

-- Cria o diretório de saves se ele não existir
createSaveDirectory :: IO ()
createSaveDirectory = createDirectoryIfMissing True baseDir

-- Função auxiliar para validar o estado do jogo (por exemplo, vidas não negativas)
validGameState :: GameState -> Bool
validGameState gs = lives gs >= 0

-- Salva o estado do jogo em um arquivo JSON.
-- Recebe o nome do arquivo e o GameState, retornando um Either com mensagem de erro ou sucesso.
saveGame :: FilePath -> GameState -> IO (Either String ())
saveGame fileName gameState = do
    createSaveDirectory  -- Garante que o diretório existe
    let fullPath = baseDir ++ "/" ++ fileName
    result <- try (B.writeFile fullPath (encode gameState)) :: IO (Either SomeException ())
    return $ case result of
        Left err -> Left $ "Erro ao salvar jogo: " ++ show err
        Right _  -> Right ()

-- Carrega o estado do jogo a partir de um arquivo JSON.
-- Recebe o nome do arquivo e retorna um Either com mensagem de erro ou o GameState carregado.
loadGame :: FilePath -> IO (Either String GameState)
loadGame fileName = do
    createSaveDirectory  -- Garante que o diretório existe
    let fullPath = baseDir ++ "/" ++ fileName
    fileExists <- doesFileExist fullPath
    if not fileExists
        then return $ Left "Arquivo não encontrado."
        else do
            result <- try (B.readFile fullPath) :: IO (Either SomeException B.ByteString)
            case result of
                Left err -> return $ Left ("Erro ao carregar jogo: " ++ show err)
                Right content -> case decode content of
                    Just gs -> if validGameState gs 
                                then return (Right gs)
                                else return (Left "Dados corrompidos ou inconsistentes.")
                    Nothing -> return (Left "Erro: Formato do arquivo inválido.")