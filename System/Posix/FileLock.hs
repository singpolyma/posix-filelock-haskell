module System.Posix.FileLock (lock,unlock,withLock,FileLock,LockType(..)) where

import Control.Exception (bracket)
import Control.Monad.IO.Class (MonadIO(..), liftIO)
import qualified System.Posix.Files as Posix
import qualified System.Posix.IO as Posix
import qualified System.Posix.Types as Posix
import System.IO

data FileLock = FileLock Posix.Fd Posix.FileLock
data LockType = ReadLock | WriteLock deriving (Eq, Show, Read)

-- | Gets the lock, executes the IO action, and then releases the lock.
--   Releases the lock even if an exception occurs.
withLock :: (MonadIO m) => FilePath -> LockType -> IO a -> m a
withLock pth t x = liftIO $ bracket (lock pth t) unlock (const x)

-- | Get a lock of the given type on the given path
lock :: (MonadIO m) => FilePath -> LockType -> m FileLock
lock pth t = liftIO $ do
	fd <- Posix.openFd pth om mode Posix.defaultFileFlags
	-- WARNING: I've been told the following line blocks the whole process?
	Posix.waitToSetLock fd (req, AbsoluteSeek, 0, 0)
	return $ FileLock fd (Posix.Unlock, AbsoluteSeek, 0, 0)
	where
	mode =
		Just $ Posix.unionFileModes Posix.ownerReadMode Posix.ownerWriteMode
	om = case t of
		ReadLock -> Posix.ReadOnly
		WriteLock -> Posix.WriteOnly
	req = case t of
		ReadLock -> Posix.ReadLock
		WriteLock -> Posix.WriteLock

-- | Release a lock
unlock :: (MonadIO m) => FileLock -> m ()
unlock (FileLock fd lck) = liftIO $ do
	Posix.setLock fd lck
	Posix.closeFd fd
