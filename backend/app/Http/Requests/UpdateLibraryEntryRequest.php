<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Validation\Rule;

class UpdateLibraryEntryRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'status'         => ['sometimes', 'required', 'string', Rule::in(['Wishlist', 'Backlog', 'Sedang Dimainkan', 'Tamat', 'Dropped'])],
            'rating_pribadi' => ['nullable', 'integer', 'min:1', 'max:10'],
            'jam_main'       => ['nullable', 'numeric', 'min:0'],
            'catatan'        => ['nullable', 'string', 'max:2000'],
        ];
    }

    /**
     * Custom validation messages.
     */
    public function messages(): array
    {
        return [
            'status.required'        => 'Status bermain wajib dipilih.',
            'status.in'              => 'Status harus salah satu dari: Wishlist, Backlog, Sedang Dimainkan, Tamat, Dropped.',
            'rating_pribadi.integer' => 'Rating pribadi harus berupa bilangan bulat.',
            'rating_pribadi.min'     => 'Rating pribadi minimal bernilai 1.',
            'rating_pribadi.max'     => 'Rating pribadi maksimal bernilai 10.',
            'jam_main.numeric'       => 'Jam bermain harus berupa angka.',
            'jam_main.min'           => 'Jam bermain tidak boleh bernilai negatif.',
        ];
    }

    /**
     * Handle failed validation for API response format.
     */
    protected function failedValidation(Validator $validator)
    {
        throw new HttpResponseException(response()->json([
            'success' => false,
            'message' => $validator->errors()->first(),
            'errors'  => $validator->errors(),
        ], 422));
    }
}
