from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status  # Add this import
from django.shortcuts import get_object_or_404  # Add this import
from .models import Book
from .serializers import BookSerializer
from django.views.generic import TemplateView


class HealthView(APIView):
    def get(self, request, *args, **kwargs):
        return Response({
            "status": "ok"
        })


health_view = HealthView.as_view()


class BookView(APIView):
    def get(self, request, *args, **kwargs):
        all_books = Book.objects.all()  # Get all books
        serializer = BookSerializer(all_books, many=True)
        return Response(serializer.data)

    def post (self, request, *args, **kwargs):
        data = request.data

        serializer = BookSerializer(data=data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)
    
    def put(self, request, *args, **kwargs):
        """Update a book by ID passed in request data"""
        book_id = request.data.get('id')
        if not book_id:
            return Response(
                {"error": "Book ID is required"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        book = get_object_or_404(Book, id=book_id)
        serializer = BookSerializer(book, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)

    def delete(self, request, *args, **kwargs):
        """Delete a book by ID passed in request data"""
        book_id = request.data.get('id')
        if not book_id:
            return Response(
                {"error": "Book ID is required"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        book = get_object_or_404(Book, id=book_id)
        book.delete()
        return Response(
            {"message": f"Book with ID {book_id} deleted successfully"}, 
            status=status.HTTP_204_NO_CONTENT
        )


book_view = BookView.as_view()


class BookManagerView(TemplateView):
    template_name = 'api/book_manager.html'


book_manager_view = BookManagerView.as_view()

