//
//  main.swift
//  CAToneFileGeneratorSwift
//
//  Created by Max Harris on 10/30/20.
//

// xxd --seek +0x00000ff0 880.000-square.aif | less

import Foundation

import AudioToolbox
import Darwin // for exit()

let SAMPLE_RATE: Float64 = 44100
let DURATION = 5.0
let FILENAME_FORMAT = "square.aif"

if CommandLine.arguments.count != 2 {
    print("Usage: CAToneFileGenerator \n\n(where n is tone in Hz)")
    exit(0)
}

let hz = Float64(CommandLine.arguments[1]) ?? 1.0
print("generating \(hz) Hz tone")

let fileName = "/\(String(describing: hz))-\(FILENAME_FORMAT)"
let filePath = FileManager.default.currentDirectoryPath + fileName
let fileURL = NSURL(fileURLWithPath: filePath)

var asbd = AudioStreamBasicDescription(
    mSampleRate: SAMPLE_RATE,
    mFormatID: kAudioFormatLinearPCM,
    mFormatFlags: kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
    mBytesPerPacket: 2,
    mFramesPerPacket: 1,
    mBytesPerFrame: 2,
    mChannelsPerFrame: 1,
    mBitsPerChannel: 16,
    mReserved: 0 // tweak for alignment to 8-bit bytes. always set this to 0
)

var audioFile: AudioFileID?
var audioErr: OSStatus? = OSStatus(noErr)
audioErr = AudioFileCreateWithURL(fileURL, UInt32(kAudioFileAIFFType), &asbd, AudioFileFlags.eraseFile, &audioFile)

// Start writing samples
let maxSampleCount = SAMPLE_RATE
var sampleCount: CLong = 0
var bytesToWrite: UInt32 = 2
let wavelengthInSamples = SAMPLE_RATE / hz

while sampleCount < Int(maxSampleCount) {
    for i in 0 ... Int(wavelengthInSamples) {
        // Square Wave
        // var sample: Int16 = (i < Int(wavelengthInSamples) / 2 ? Int16.max : Int16.min).byteSwapped

        // Saw Wave
        // var sample = Int16(((Double(i) / wavelengthInSamples) * Double(Int16.max) * 2) - Double(Int16.max)).byteSwapped

        // Sin Wave
        var sample = Int16(Double(Int16.max) * sin(2 * Double.pi * (Double(i) / wavelengthInSamples))).byteSwapped

        audioErr = AudioFileWriteBytes(audioFile!, false, Int64(sampleCount * 2), &bytesToWrite, &sample)
        sampleCount += 1
    }
}

audioErr = AudioFileClose(audioFile!)
assert(audioErr == noErr)
print("wrote \(sampleCount) samples")
