//
//  UnattachedFiles.swift
//

import Foundation

func removeUnattachedFiles(run: Run) -> Int {
    let skippedFiles = ["report.junit"]
    let fileManager = FileManager.default
    var removedFiles = 0
    var attachmentPathsLastItem = run.allAttachments.map { $0.source?.lastPathComponent() } // これがmergeするとすべてのattachmentsが入っていない
    if case RenderingContent.url(let url) = run.logContent {
        attachmentPathsLastItem.append(url.lastPathComponent)
    }

    func shouldBeDeleted(fileURL: URL) -> Bool {
        /// Do not delete directories
        //Logger.success("fileURL: \(fileURL.absoluteString)")
        // fileURLが添付ファイルのURL
        var isDir: ObjCBool = false
        // fileURLのfileが存在するかをチェック
        if fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDir), isDir.boolValue {
            return false
        }

        let lastPathComponent = fileURL.lastPathComponent // file name
        Logger.success("lastPathComponent: \(lastPathComponent.description)")
        Logger.success("attachmentPathsLastItem: \(attachmentPathsLastItem.description)")
        // mergeしたxcresultの構造がよくわからん
        // file名がattachmentPathsLastItemに含まれているかチェック
        if attachmentPathsLastItem.contains(lastPathComponent) {
            Logger.success("don't remove the file!222!")
            return false
        }

//        if lastPathComponent.contains("refs.") {
//            let lastPath = lastPathComponent.components(separatedBy: ".")[1]
//            if attachmentPathsLastItem.contains(lastPath) {
//                Logger.success("don't remove the file!!")
//                return false
//            }
//        }

        // refs.0~SlJvHrwqb8jYmpj647X2B9TFJSIAJMbuowa5c02HKfLAFtH280mpGHkSKnma-C12Fr6NtQvCt24QsYjNxf_4Zg==
        // 最初にrefsという文字が入ってしまったので検索に引っかからなかった。
//        Logger.success("drop:: \(String(lastPathComponent.dropFirst(5)))")
//        if attachmentPathsLastItem.contains(String(lastPathComponent.dropFirst(5))) { // remove first `ref.`
//
//            return false
//        }

        // skippedFileに含まれているかチェック
        if skippedFiles.contains(lastPathComponent) {
            return false
        }

        // マージしたときはこれじゃ足りないみたい
        // searchFileURLsのURLが足りないのか？
        // shouldBeDeletedのif文が足りないのか
        // マージしたときのURLsと普通のときのURLsの違いを知りたい

        // attachmentPathsLastItemに添付ファイルのpathが登録されてないっぽい
        // mergeしたときの添付ファイルmerged_report_after_d.xcresult直下にあった
        Logger.success("remove the file!!")
        return true
    }

    func searchFileURLs() throws -> [URL] {
        let topContents = try fileManager.contentsOfDirectory(at: run.file.url, includingPropertiesForKeys: nil)
        //Logger.success("topContents: \(topContents.description)")
        let dataContents = try fileManager.contentsOfDirectory(at: run.file.url.appendingPathComponent("Data"), includingPropertiesForKeys: nil)
        //Logger.success("dataContents: \(dataContents.description)")
        return topContents + dataContents
    }

    do {
        for fileURL in try searchFileURLs() {
            if shouldBeDeleted(fileURL: fileURL) {
                //try fileManager.removeItem(at: fileURL)
                removedFiles += 1
            }
        }
    } catch {
        Logger.error("Error while removing files \(error.localizedDescription)")
    }
    return removedFiles
}

