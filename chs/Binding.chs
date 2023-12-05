{-#LANGUAGE ForeignFunctionInterface #-}
{-#LANGUAGE OverloadedStrings #-}
{-#LANGUAGE CPP #-}
#include "proteaaudio_binding.h"

#if defined PROTEAAUDIO_SDL
{-|
ProteaAudio-SDL is a stereo audio mixer and playback library for SDL /(platform independent)/
-}
module Sound.ProteaAudio.SDL (
#elif defined PROTEAAUDIO_RT
{-|
ProteaAudio is a stereo audio mixer/playback library for

* Linux /(PusleAudio)/

* Macintosh OS X /(CoreAudio)/

* Windows /(DirectSound)/
-}
module Sound.ProteaAudio (
#else
#error "I can't decide which binding to compile; please define either PROTEAAUDIO_SDL or PROTEAAUDIO_RT"
#endif
    -- * Sample
    Sample(),
    Sound(),

    -- * Audio System Setup
    initAudio,
    finishAudio,

    -- * Main Mixer
    volume,
    soundActiveAll,
    soundStopAll,

    -- * Sample Loading
    loaderAvailable,
    sampleFromMemoryPcm,
    sampleFromMemoryWav,
    sampleFromMemoryOgg,
    sampleFromMemoryMp3,
    sampleFromMemory,
    sampleFromFile,
    sampleDestroy,

    -- * Sample Playback
    soundLoop,
    soundPlay,
    soundLoopOn,
    soundPlayOn,
    soundUpdate,
    soundStop,
    soundActive,
    soundPos,
    soundPaused
 ) where

import Foreign
import Foreign.C
import Data.ByteString (ByteString)
import qualified Data.ByteString as BS

-- | Audio sample resource handle. A sample can be shared between multiple Sound tracks. (abstraction for data)
newtype Sample = Sample{ fromSample :: {#type sample_t#} }

-- | Sound track handle. It is used to control the audio playback. (abstraction for playback)
newtype Sound = Sound{ fromSound :: {#type sound_t#} }


-- | Initializes the audio system.
{#fun initAudio
    { `Int' -- ^ the maximum number of sounds that are played parallely, at most 1024. Computation time is linearly correlated to this factor.
    , `Int' -- ^ sample frequency of the playback in Hz. 22050 corresponds to FM radio 44100 is CD quality. Computation time is linearly correlated to this factor.
    , `Int' -- ^ the number of bytes that are sent to the sound card at once. Low numbers lead to smaller latencies but need more computation time (thread switches). If a too small number is chosen, the sounds might not be played continuously. The default value 512 guarantees a good latency below 40 ms at 22050 Hz sample frequency.
    } -> `Bool' -- ^ returns True on success
#}

-- *

-- | Releases the audio device and cleans up resources.
{#fun finishAudio {} -> `()'#}

-- | Checks if loader for this file type is available.
{#fun loaderAvailable
  { `String' -- ^ file extension (e.g. ogg)
  } -> `Bool'
#}


-- | Loads raw linear pcm sound sample from memory buffer.
{#fun _sampleFromMemoryPcm
  { id `Ptr CChar' -- ^ memory buffer pointer
  , `Int' -- ^ memory buffer size in bytes
  , `Int' -- ^ number of channels, e.g. 1 for mono, 2 for stereo.
  , `Int' -- ^ sample rate, i.e. 44100 Hz
  , `Int' -- ^ bits per sample, i.e. 8, 16, 32
  , `Float' -- ^ volume
  } -> `Sample' Sample -- ^ returns handle
#}

-- | Loads wav sound sample from memory buffer.
{#fun _sampleFromMemoryWav
  { id `Ptr CChar' -- ^ memory buffer pointer
  , `Int' -- ^ memory buffer size in bytes
  , `Float' -- ^ volume
  } -> `Sample' Sample -- ^ returns handle
#}

-- | Loads ogg sound sample from memory buffer.
{#fun _sampleFromMemoryOgg
  { id `Ptr CChar' -- ^ memory buffer pointer
  , `Int' -- ^ memory buffer size in bytes
  , `Float' -- ^ volume
  } -> `Sample' Sample -- ^ returns handle
#}

-- | Loads mp3 sound sample from memory buffer.
{#fun _sampleFromMemoryMp3
  { id `Ptr CChar' -- ^ memory buffer pointer
  , `Int' -- ^ memory buffer size in bytes
  , `Float' -- ^ volume
  } -> `Sample' Sample -- ^ returns handle
#}

-- | Loads raw linear pcm sound sample from memory buffer.
sampleFromMemoryPcm :: ByteString -- ^ pcm sample data; array of pcm samples (signed 8 bit int, signed 16 bit int or 32 bit float)
                    -> Int -- ^ number of channels, e.g. 1 for mono, 2 for stereo.
                    -> Int -- ^ sample rate, i.e. 44100 Hz
                    -> Int -- ^ bits per sample, i.e. 8, 16, 32
                    -> Float -- ^ volume
                    -> IO Sample -- ^ return sample handle
sampleFromMemoryPcm pcmData channels sampleRate bitsPerSample volume =
  BS.useAsCStringLen pcmData $ \(ptr, size) -> _sampleFromMemoryPcm ptr size channels sampleRate bitsPerSample volume

-- | Loads wav sound sample from memory buffer.
sampleFromMemoryWav :: ByteString -- ^ wav sample data
                    -> Float -- ^ volume
                    -> IO Sample -- ^ return sample handle
sampleFromMemoryWav wavData volume = BS.useAsCStringLen wavData $ \(ptr, size) -> _sampleFromMemoryWav ptr size volume

-- | Loads ogg sound sample from memory buffer.
sampleFromMemoryOgg :: ByteString -- ^ ogg sample data
                    -> Float -- ^ volume
                    -> IO Sample -- ^ return sample handle
sampleFromMemoryOgg oggData volume = BS.useAsCStringLen oggData $ \(ptr, size) -> _sampleFromMemoryOgg ptr size volume

-- | Loads mp3 sound sample from memory buffer.
sampleFromMemoryMp3 :: ByteString -- ^ mp3 sample data
                    -> Float -- ^ volume
                    -> IO Sample -- ^ return sample handle
sampleFromMemoryMp3 mp3Data volume = BS.useAsCStringLen mp3Data $ \(ptr, size) -> _sampleFromMemoryMp3 ptr size volume

-- | Loads wav, ogg or mp3 sound sample from memory buffer (autodetects audio format).
sampleFromMemory :: ByteString -> Float -> IO Sample
sampleFromMemory bs volume
  | BS.take 4 bs == "RIFF"
  = sampleFromMemoryWav bs volume
  | BS.take 4 bs == "OggS"
  = sampleFromMemoryOgg bs volume
  | BS.take 3 bs == "ID3" || BS.take 2 bs `elem` ["\xFF\xFB", "\xFF\xF3", "\xFF\xF2"]
  = sampleFromMemoryMp3 bs volume
  | otherwise
  = error "Could not detect audio format"

-- | Loads a sound sample from file.
{#fun sampleFromFile
  { `String' -- ^ sample filepath
  , `Float' -- ^ volume
  } -> `Sample' Sample -- ^ returns handle
#}

-- | Unloads a previously loaded sample from memory, invalidating the handle.
{#fun sampleDestroy {fromSample `Sample'} -> `Bool'#}

-- | Set main mixer volume.
{#fun volume
  { `Float' -- ^ left
  , `Float' -- ^ right
  } -> `()'
#}

-- | Return the number of currently active sounds.
{#fun soundActiveAll {} -> `Int'#}

-- | Stops all sounds immediately.
{#fun soundStopAll {} -> `()'#}

-- | Plays a specified sound sample continuously any free channel and sets its parameters.
{#fun soundLoop
  { fromSample `Sample' -- ^ handle of a previously loaded sample
  , `Float' -- ^ left volume
  , `Float' -- ^ right volume
  , `Float' -- ^ time difference between left and right channel in seconds. Use negative values to specify a delay for the left channel, positive for the right
  , `Float' -- ^ pitch factor for playback. 0.5 corresponds to one octave below, 2.0 to one above the original sample
  } -> `Sound' Sound
#}

-- | Plays a specified sound sample once any free channel and sets its parameters.
{#fun soundPlay
  { fromSample `Sample' -- ^ handle of a previously loaded sample
  , `Float' -- ^ left volume
  , `Float' -- ^ right volume
  , `Float' -- ^ time difference between left and right channel in seconds. Use negative values to specify a delay for the left channel, positive for the right
  , `Float' -- ^ pitch factor for playback. 0.5 corresponds to one octave below, 2.0 to one above the original sample
  } -> `Sound' Sound
#}

-- | Plays a specified sound sample once on a specific channel and sets its parameters.
{#fun soundPlayOn
  { `Int' -- ^ number of the channel to use for playback with the first channel starting at 0
  , fromSample `Sample' -- ^ handle of a previously loaded sample
  , `Float' -- ^ left volume
  , `Float' -- ^ right volume
  , `Float' -- ^ time difference between left and right channel in seconds. Use negative values to specify a delay for the left channel, positive for the right
  , `Float' -- ^ pitch factor for playback. 0.5 corresponds to one octave below, 2.0 to one above the original sample
  } -> `Sound' Sound
#}

-- | Plays a specified sound sample continuously on a specific channel and sets its parameters.
{#fun soundLoopOn
  { `Int' -- ^ number of the channel to use for playback with the first channel starting at 0
  , fromSample `Sample' -- ^ handle of a previously loaded sample
  , `Float' -- ^ left volume
  , `Float' -- ^ right volume
  , `Float' -- ^ time difference between left and right channel in seconds. Use negative values to specify a delay for the left channel, positive for the right
  , `Float' -- ^ pitch factor for playback. 0.5 corresponds to one octave below, 2.0 to one above the original sample
  } -> `Sound' Sound
#}

-- | Updates parameters of a specified sound.
{#fun soundUpdate
  { fromSound `Sound' -- ^ handle of a currently active sound (if sound has stopped, this is a no-op)
  , `Bool' -- ^ is paused state, this does not change the sound active state
  , `Float' -- ^ left volume
  , `Float' -- ^ right volume
  , `Float' -- ^ time difference between left and right channel in seconds. Use negative values to specify a delay for the left channel, positive for the right
  , `Float' -- ^ pitch factor for playback. 0.5 corresponds to one octave below, 2.0 to one above the original sample
  } -> `Bool' -- ^ return True in case the parameters have been updated successfully
#}

-- | Stops a specified sound immediately.
{#fun soundStop {fromSound `Sound'} -> `Bool'#}

-- | Checks if a specified sound is still active.
{#fun soundActive{fromSound `Sound'} -> `Bool'#}

{#fun soundPos{fromSound `Sound'} -> `Double'#}
{#fun soundPaused{fromSound `Sound'} -> `Bool'#}
