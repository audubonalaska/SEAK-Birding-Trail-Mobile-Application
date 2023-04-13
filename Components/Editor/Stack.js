// program to implement stack data structure

// program to implement stack data structure
  var undoList = []
  var redoList = []

  function init(){
        undoList = [];
        redoList = []
    }


    // add element to the stack
   function addToUndoList(element) {
        return undoList.push(element);
    }

    // remove element from the stack
    function removeFromUndoList() {
        if(undoList.length > 0) {

            return undoList.pop();
        }
    }

    // view the last element
   function  peekUndoList() {
        return undoList[undoList.length - 1];
    }

    // check if the stack is empty
    function isEmptyUndoList(){
        return undoList.length == 0;
    }

    // the size of the stack
   function  sizeUndoList(){
        return undoList.length;
    }

      // add element to the stack
   function addToRedoList(element) {
        return redoList.push(element);
    }

    // remove element from the stack
    function removeFromRedoList() {
        if(redoList.length > 0) {
            return redoList.pop();
        }
    }

    // view the last element
   function  peekRedoList() {
        return redoList[undoList.length - 1];
    }

    // check if the stack is empty
    function isEmptyRedoList(){
        return redoList.length == 0;
    }

    // the size of the stack
   function  sizeRedoList(){
        return redoList.length;
    }

    // empty the stack
    function clear(){
        undoList = [];
        redoList = [];
    }



