%
% (c) The AQUA Project, Glasgow University, 1994-1997
%

\section[PrelMain]{Module @PrelMain@}

\begin{code}
{-# OPTIONS -#include "cbits/stgio.h" #-}

module PrelMain( mainIO ) where

import Prelude
import {-# SOURCE #-} qualified Main	-- for type of "Main.main"
import IO 		( hFlush, hPutStr, stdout, stderr )
import PrelAddr 	( Addr )
import PrelException
import PrelPack     ( packString )
import PrelArr      ( ByteArray(..) )
\end{code}

\begin{code}
mainIO :: IO ()		-- It must be of type (IO t) because that's what
			-- the RTS expects.  GHC doesn't check this, so
			-- make sure this type signature stays!
mainIO = catchException Main.main handler

-- make sure we handle errors while reporting the error!
-- (e.g. evaluating the string passed to 'error' might generate
--  another error, etc.)

handler :: Exception -> IO ()
handler err = catchException (real_handler err) handler

real_handler :: Exception -> IO ()
real_handler ex =
  case ex of
	AsyncException StackOverflow -> reportStackOverflow
	ErrorCall s -> reportError s
	other       -> reportError (showsPrec 0 other "\n")

reportStackOverflow :: IO ()
reportStackOverflow = do
   (hFlush stdout) `catchException` (\ _ -> return ())
   callStackOverflowHook
   stg_exit 2  

reportError :: String -> IO ()
reportError str = do
   (hFlush stdout) `catchException` (\ _ -> return ())
   let bs@(ByteArray (_,len) _) = packString str
   writeErrString (``&ErrorHdrHook''::Addr) bs len
   stg_exit 1

foreign import ccall "writeErrString__" 
	writeErrString :: Addr -> ByteArray Int -> Int -> IO ()

foreign import ccall "stackOverflow"
	callStackOverflowHook :: IO ()

foreign import ccall "stg_exit"
	stg_exit :: Int -> IO ()

\end{code}
