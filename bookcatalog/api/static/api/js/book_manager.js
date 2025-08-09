/* filepath: \\wsl.localhost\Ubuntu-22.04\home\feto2\devops-camp\bookcatalog\api\static\api\js\book_manager.js */
const apiUrl = '/api/books/';
const tableBody = document.querySelector('#books-table tbody');
const form = document.getElementById('book-form');
const cancelEditBtn = document.getElementById('cancel-edit');

function fetchBooks() {
    fetch(apiUrl)
        .then(res => res.json())
        .then(data => {
            tableBody.innerHTML = '';
            data.forEach(book => {
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>${book.id}</td>
                    <td>${book.title}</td>
                    <td>${book.description || ''}</td>
                    <td>${book.author}</td>
                    <td>${book.new_field || ''}</td>
                    <td>${book.created_at ? new Date(book.created_at).toLocaleString() : ''}</td>
                    <td class="actions">
                        <button onclick="editBook(${book.id})">Edit</button>
                        <button onclick="deleteBook(${book.id})">Delete</button>
                    </td>
                `;
                tableBody.appendChild(row);
            });
        });
}

window.editBook = function(id) {
    fetch(apiUrl)
        .then(res => res.json())
        .then(data => {
            const book = data.find(b => b.id === id);
            if (book) {
                document.getElementById('book-id').value = book.id;
                document.getElementById('title').value = book.title;
                document.getElementById('description').value = book.description;
                document.getElementById('author').value = book.author;
                document.getElementById('new_field').value = book.new_field;
                cancelEditBtn.style.display = '';
            }
        });
}

window.deleteBook = function(id) {
    if (!confirm('Delete this book?')) return;
    fetch(apiUrl, {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id })
    }).then(() => fetchBooks());
}

form.onsubmit = function(e) {
    e.preventDefault();
    const id = document.getElementById('book-id').value;
    const title = document.getElementById('title').value;
    const description = document.getElementById('description').value;
    const author = document.getElementById('author').value;
    const new_field = document.getElementById('new_field').value;
    const payload = { title, description, author, new_field };
    if (id) payload.id = id;
    
    fetch(apiUrl, {
        method: id ? 'PUT' : 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
    })
    .then(res => res.json())
    .then(() => {
        form.reset();
        document.getElementById('book-id').value = '';
        cancelEditBtn.style.display = 'none';
        fetchBooks();
    });
};

cancelEditBtn.onclick = function() {
    form.reset();
    document.getElementById('book-id').value = '';
    cancelEditBtn.style.display = 'none';
};

// Initialize the page
document.addEventListener('DOMContentLoaded', function() {
    fetchBooks();
});