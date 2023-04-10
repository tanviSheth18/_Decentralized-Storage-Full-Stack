// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DStorage {
  string public name = 'DStorage';
  uint public fileCount = 0;
  uint public folderCount = 0;

  mapping(uint => File) public files;
  mapping(uint => Folder) public folders;

  struct File {
  uint fileId;
  string fileHash;
  uint fileSize;
  string fileType;
  string fileName;
  string fileDescription;
  uint uploadTime;
  address payable uploader;
    uint folderId;

}

struct Folder {
  uint folderId;
  string folderName;
  uint creationTime;
  address payable owner;
  uint[] fileIds;
}

  event FileUploaded(
    uint fileId,
    string fileHash,
    uint fileSize,
    string fileType,
    string fileName, 
    string fileDescription,
    uint uploadTime,
    address payable uploader,
    uint folderId
  );

  event FileDeleted(
    uint fileId,
    string fileHash,
    uint fileSize,
    string fileType,
    string fileName, 
    string fileDescription,
    uint uploadTime,
    address payable uploader,
    uint folderId

  );

  event FileRenamed(
    uint fileId,
    string fileHash,
    uint fileSize,
    string fileType,
    string fileName, 
    string fileDescription,
    uint uploadTime,
    address payable uploader,
    uint folderId
  );

  event FolderCreated(
  uint folderId,
  string folderName,
  uint creationTime,
  address payable owner
  );

  event FolderDeleted(
  uint folderId,
  string folderName,
  uint creationTime,
  address payable owner
  );

  constructor() public {
  }

  function uploadFile(string memory _fileHash, uint _fileSize, string memory _fileType, string memory _fileName, string memory _fileDescription,uint folderId) public {
    // Make sure the file hash exists
    require(bytes(_fileHash).length > 0);
    // Make sure file type exists
    require(bytes(_fileType).length > 0);
    // Make sure file description exists
    require(bytes(_fileDescription).length > 0);
    // Make sure file fileName exists
    require(bytes(_fileName).length > 0);
    // Make sure uploader address exists
    require(msg.sender!=address(0));
    // Make sure file size is more than 0
    require(_fileSize>0);
    //Make sure folder exists
    require(_folderId > 0 && _folderId <= folderCount, "Folder does not exist");

    // Increment file id
    fileCount ++;

    // Add File to the contract
    files[fileCount] = File(fileCount, _fileHash, _fileSize, _fileType, _fileName, _fileDescription, now, msg.sender, _folderId);
    // Trigger an event
    emit FileUploaded(fileCount, _fileHash, _fileSize, _fileType, _fileName, _fileDescription, now, msg.sender, _folderId);
  }

  function deleteFile(uint _fileId) public {
    // Check that the file exists
    require(_fileId > 0 && _fileId <= fileCount, "File does not exist");
    // Retrieve the file
    File storage file = files[_fileId];
    // Make sure only the uploader can delete the file
    require(msg.sender == file.uploader, "Only the uploader can delete this file");

    // Remove the file from the folder's fileIds array
    uint folderId = file.folderId;
    uint[] storage folderFileIds = folders[folderId].fileIds;
    for (uint i = 0; i < folderFileIds.length; i++) {
      if (folderFileIds[i] == _fileId) {
        // Shift the remaining elements to the left
        for (uint j = i; j < folderFileIds.length - 1; j++) {
          folderFileIds[j] = folderFileIds[j+1];
        }
        // Remove the last element
        folderFileIds.pop();
        break;
      }
    }

  // Remove the file from the contract
  delete files[_fileId];
  // Trigger an event
  emit FileDeleted(_fileId, file.fileHash, file.fileSize, file.fileType, file.fileName, file.fileDescription, file.uploadTime, file.uploader, folderId);
}


    function renameFile(uint _fileId, string memory _newFileName) public {
    // Check that the file exists
    require(_fileId > 0 && _fileId <= fileCount, "File does not exist");
    // Retrieve the file
    File storage file = files[_fileId];
    // Make sure only the uploader can rename the file
    require(msg.sender == file.uploader, "Only the uploader can rename this file");
    // Make sure the new file name exists
    require(bytes(_newFileName).length > 0, "New file name cannot be empty");

    // Update the file name
    file.fileName = _newFileName;
    uint folderId = file.folderId; // add this line to get the folder id
    // Trigger an event
    emit FileRenamed(_fileId, file.fileHash, file.fileSize, file.fileType, _newFileName, file.fileDescription, file.uploadTime, file.uploader, folderId);
  }

  function getUserFiles() public view returns (string[] memory) {
    // Create an array to store file names
    string[] memory fileNames = new string[](fileCount);
    uint numberOfFiles = 0;
    
    // Iterate through all files in the contract
    for (uint i = 1; i <= fileCount; i++) {
      // Check if the file was uploaded by the sender
      if (files[i].uploader == msg.sender) {
        fileNames[numberOfFiles] = files[i].fileName;
        numberOfFiles++;
      }
    }
    // Return the array of file names uploaded by the sender
    return fileNames;
}

  function searchUserFilesByName(string memory _fileName) public view returns (File[] memory) {
    // Create an array to store files
    File[] memory userFiles = new File[](fileCount);
    uint numberOfFiles = 0;
    
    // Iterate through all files in the contract
    for (uint i = 1; i <= fileCount; i++) {
      // Check if the file was uploaded by the sender and matches the search query
      if (files[i].uploader == msg.sender && keccak256(bytes(files[i].fileName)) == keccak256(bytes(_fileName))) {
        userFiles[numberOfFiles] = files[i];
        numberOfFiles++;
      }
    }
  
    // Resize the userFiles array to the correct size
    assembly {
      mstore(userFiles, numberOfFiles)
    }
    
    return userFiles;
  }

  function createFolder(string memory _folderName) public {
    // Make sure folder name exists
    require(bytes(_folderName).length > 0);
    // Increment folder id
    folderCount ++;
    // Add Folder to the contract
    folders[folderCount] = Folder(folderCount, _folderName, now, msg.sender);
    // Trigger an event
    emit FolderCreated(_folderCount, _folderName, now, _owner)
  }

  function deleteFolder(uint _folderId) public {
    // Check that the folder exists
    require(_folderId > 0 && _folderId <= folderCount, "Folder does not exist");
    // Retrieve the folder
    Folder storage folder = folders[_folderId];
    // Make sure only the owner can delete the folder
    require(msg.sender == folder.owner, "Only the owner can delete this folder");

    // Delete all the files in the folder
    uint[] storage fileIds = folder.fileIds;
    for (uint i = 0; i < fileIds.length; i++) {
      uint fileId = fileIds[i];
      deleteFile(fileId);
    }

    // Remove the folder from the contract
    delete folders[_folderId];
    // Trigger an event
    emit FolderDeleted(_folderId, folder.folderName, folder.creationTime, folder.owner);
}

  function addFileToFolder(uint _fileId, uint _folderId) public {
  // Check that the file exists
  require(_fileId > 0 && _fileId <= fileCount, "File does not exist");
  // Check that the folder exists
  require(_folderId > 0 && _folderId <= folderCount, "Folder does not exist");
  // Retrieve the file and folder
  File storage file = files[_fileId];
  Folder storage folder = folders[_folderId];
  // Make sure only the folder owner can add files to the folder
  require(msg.sender == folder.owner, "Only the folder owner can add files to this folder");

  // Add the file to the folder
  folder.files.push(file);
    }

function getUserFolders() public view returns (string[] memory) {
  // Create an array to store folder names
  string[] memory folderNames = new string[](folderCount);
  uint numberOfFolders = 0;

  // Iterate through all folders in the contract
  for (uint i = 1; i <= folderCount; i++) {
    // Check if the folder was created by the sender
    if (folders[i].owner == msg.sender) {
      folderNames[numberOfFolders] = folders[i].folderName;
      numberOfFolders++;
    }
  }

  // Resize the folderNames array to the correct size
  assembly {
    mstore(folderNames, numberOfFolders)
  }

  return folderNames;
}

  function getFolderFiles(uint _folderId) public view returns (File[] memory) {
  // Check that the folder exists
  require(_folderId > 0 && _folderId <= folderCount, "Folder does not exist");
  // Retrieve the folder
  Folder storage folder = folders[_folderId];
  // Return the files in the folder
  return folder.files;
  }
}


